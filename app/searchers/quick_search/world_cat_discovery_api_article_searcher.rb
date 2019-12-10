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
    def item_link(bib)
      doi_link = bib.same_as&.to_s

      # Return DOI link, if available
      if doi_link
        doi_base_url = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['doi_link']
        return doi_base_url + doi_link
      end

      # Return link WorldCat OpenUrl link resolver, if available
      open_url_link = link_from_open_url(bib)
      return open_url_link if open_url_link

      # Otherwise just return link to OCLC catalog
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
      link = UmdOpenUrl::Resolver.parse_response(json)

      link
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

      # Return nil if the necessary parameters weren't found.
      return nil unless issn && volume && issue_number && page_start && date_published

      open_url_resolver_service_link =
        QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['open_url_resolver_service_link']
      open_url_wskey = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['world_cat_open_url_wskey']

      b = UmdOpenUrl::Builder.new(open_url_resolver_service_link)
      b.custom_param('wskey', open_url_wskey).issn(issn).volume(volume).start_page(page_start)
       .publication_date(date_published)

      url = b.build

      url
    end
  end
end

