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

    # Returns the link to use for the given item.
    def item_link(bib)
      doi_link = doi_generator(bib)

      # Return DOI link, in one exists
      return doi_link if doi_link

      # Query OpenURL resolve service for results
      open_url_links = open_url_generator(bib)
      if open_url_links.size.positive?
        # If there is only one result, return it
        return open_url_links[0] if open_url_links.size == 1

        # If there are multiple results, return a "Citation Finder" link
        return citation_generator(bib)
      end

      # Default -- return link to the catalog detail page
      catalog_generator(bib)
    end

    # Returns a single URL representing the link to the DOI, or nil if
    # no DOI is available
    def doi_generator(bib)
      doi_link = bib.same_as&.to_s

      # Return DOI link, if available
      return nil unless doi_link

      Rails.logger.debug('QuickSearch::WorldCatDiscoveryApiArticleSearcher.item_link - DOI link found. Returning.')
      doi_base_url = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['doi_link']
      doi_base_url + doi_link
    end

    # Returns a list of URLs returned by an OpenURL resolver server, or an
    # empty list if no URLs are found.
    def open_url_generator(bib)
      open_url_link = open_url_resolve_link(bib)
      links = UmdOpenUrl::Resolver.resolve(open_url_link)
      links
    end

    # Returns a URL to a citation finder server, or nil if no citation
    # finder is available
    def citation_generator(bib)
      builder = open_url_builder(
        bib, QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['citation_finder_link']
      )
      builder&.build
    end

    # Returns a URL to the catalog detail page. Should not return nil
    def catalog_generator(bib)
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['url_link'] +
        bib.oclc_number.to_s
    end

    # Overrides the "item_format" method from the superclass to always
    # return 'article'
    def item_format(_bib)
      'article'
    end

    # Returns an OpenUrlBuilder populated with information from the given
    # bib and link, or nil if an error occurs extracting the bib information
    def open_url_builder(bib, link) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      best_type = WorldCat::Discovery::Bib.choose_best_type(bib)
      return nil unless best_type.is_a? WorldCat::Discovery::Article

      article = best_type

      builder = UmdOpenUrl::Builder.new(link)

      # WorldCat code doesn't always check for nil, so wrap in begin/rescue
      # so that we can just return nil if an error occurs.
      begin
        builder.issn(article&.periodical&.issn)
        builder.volume(article&.volume&.volume_number)
        builder.issue(article&.issue&.issue_number)
        builder.start_page(article&.page_start)
        builder.publication_date(article&.date_published)
      rescue StandardError
        return nil
      end

      builder
    end

    def open_url_resolve_link(bib)
      open_url_resolver_service_link =
        QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['open_url_resolver_service_link']

      builder = open_url_builder(bib, open_url_resolver_service_link)
      return nil unless builder

      open_url_wskey = QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG['world_cat_open_url_wskey']
      builder.custom_param('wskey', open_url_wskey)

      return nil unless builder.valid?(%i[wskey issn volume issue start_page publication_date])

      builder.build
    end
  end
end
