# frozen_string_literal: true

require 'umd_open_url'

module QuickSearch
  # QuickSearch searcher for WorldCat, restricted to articles
  class WorldCatDiscoveryApiArticleSearcher < WorldCatDiscoveryApiSearcher
    def query_params
      {
        q: http_request_queries['not_escaped'],
        itemType: 'artchap',
        startIndex: @offset,
        itemsPerPage: items_per_page,
        sortBy: 'library_plus_relevance'
      }
    end

    def loaded_link
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['loaded_link'] +
        percent_encoded_raw_user_search_query
    end

    # Returns the link to use for the given item. If the item has a DOI
    # a direct link to the item is returned, otherwise a link to the
    # item in the OCLC catalog is returned.
    def item_link(bib) # rubocop:disable Metrics/MethodLength
      doi_link = bib.same_as&.to_s

      # Return DOI link, if available
      if doi_link
        Rails.logger.debug('QuickSearch::WorldCatDiscoveryApiArticleSearcher.item_link - DOI link found. Returning.')
        doi_base_url = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['doi_link']
        return doi_base_url + doi_link
      end

      # Return link WorldCat OpenUrl link resolver, if available
      link_from_open_url = link_from_open_url(bib)
      if link_from_open_url
        Rails.logger.debug(
          'QuickSearch::WorldCatDiscoveryApiArticleSearcher.item_link - OpenURL link found. Returning.'
        )
        return link_from_open_url
      end

      # Otherwise just return link to catalog detail page
      Rails.logger.debug('QuickSearch::WorldCatDiscoveryApiArticleSearcher.item_link - Defaulting to catalog detail link.')
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['url_link'] +
        bib.oclc_number.to_s
    end

    # Returns the DOI link for the given item, or nil if no DOI is present
    def doi_link(bib)
      bib.same_as&.to_s
    end

    # Overrides the "item_format" method from the superclass to always
    # return 'article'
    def item_format(_bib)
      'article'
    end

    def link_from_open_url(bib)
      # Generate the link to the WorldCat OpenUrl Resolver
      open_url_link = open_url_resolve_link(bib)
      json = UmdOpenUrl::Resolver.resolve(open_url_link)
      links = UmdOpenUrl::Resolver.parse_response(json)

      return nil if links.nil? || links.size.zero?

      if links.size == 1
        Rails.logger.debug(
          'QuickSearch::WorldCatDiscoveryApiArticleSearcher.link_from_open_url - '\
          'Single OpenURL resolved link found. Returning.'
        )
        return link[0]
      else
        Rails.logger.debug(
          'QuickSearch::WorldCatDiscoveryApiArticleSearcher.link_from_open_url - '\
          "#{links.size} OpenURL resolved links found. Returning link to citation finder"
        )
        open_url_link_uri = URI.parse(open_url_link)
        params_map = CGI.parse(open_url_link_uri.query)
        filtered_params_map = params_map.reject { |k, _v| k == 'wskey' }

        # Regenerate the query parameters string. Using Rack::Utils.build_query
        # because it produces a query string without array-based parameters
        filtered_params = Rack::Utils.build_query(filtered_params_map)

        filtered_params = nil if filtered_params.strip.empty?

        # Construct the link to the resource
        citiation_finder_uri = URI::HTTP.build(
          host: 'umaryland.on.worldcat.org',
          path: '/atoztitles/link',
          query: filtered_params
        )
        citiation_finder_uri.scheme = 'https'
        citiation_finder_url = citiation_finder_uri.to_s
        citiation_finder_url
      end
    end

    def open_url_resolve_link(bib) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      best_type = WorldCat::Discovery::Bib.choose_best_type(bib)
      return nil unless best_type.is_a? WorldCat::Discovery::Article

      article = best_type

      # WorldCat code doesn't always check for nil, so wrap in begin/rescue
      # so that we can just return nil if an error occurs.
      begin
        issn = article&.periodical&.issn
        volume = article&.volume&.volume_number
        issue_number = article&.issue&.issue_number
        page_start = article&.page_start
        date_published = article&.date_published
      rescue StandardError
        return nil
      end

      Rails.logger.debug do
        <<~LOGGER_END
          QuickSearch::WorldCatDiscoveryApiArticleSearcher.open_url_resolve_link
          \tissn: #{issn}
          \tvolume: #{volume}
          \tissue_number: #{issue_number}
          \tpage_start: #{page_start}
          \tdate_published: #{date_published}
        LOGGER_END
      end

      # Return nil if the necessary parameters weren't found.
      unless issn && volume && issue_number && page_start && date_published
        Rails.logger.debug do
          'QuickSearch::WorldCatDiscoveryApiArticleSearcher.open_url_resolve_link data missing. Returning nil'
        end

        return nil
      end

      open_url_resolver_service_link =
        QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['open_url_resolver_service_link']
      open_url_wskey = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['world_cat_open_url_wskey']

      b = UmdOpenUrl::Builder.new(open_url_resolver_service_link)
      b.custom_param('wskey', open_url_wskey).issn(issn).volume(volume)
       .issue(issue_number).start_page(page_start).publication_date(date_published)

      url = b.build

      url
    end
  end
end
