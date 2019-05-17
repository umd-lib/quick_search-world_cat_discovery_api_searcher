# frozen_string_literal: true

module QuickSearch
  # QuickSearch seacher for WorldCat
  class WorldCatDiscoveryApiSearcher < QuickSearch::Searcher
    def search
      @response = WorldCat::Discovery::Bib.search(query_params)
    end

    def results # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      return results_list[0..@per_page - 1] if results_list
      @results_list = []
      @response.bibs.each do |bib|
        result = OpenStruct.new
        result.title = bib.name
        result.link = item_link(bib)
        result.author = bib.author&.name
        result.date = bib.date_published
        result.format = plain_bib_type(bib) if include_type?
        @results_list << result
      end
      @results_list[0..@per_page - 1]
    end

    def total
      @response.total_results
    end

    def query_params
      {
        q: sanitized_user_search_query,
        startIndex: @offset,
        itemsPerPage: items_per_page,
        sortBy: 'library_plus_relevance'
      }
    end

    def loaded_link
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG['loaded_link'] +
        sanitized_user_search_query
    end

    def item_link(bib)
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG['url_link'] +
        bib.oclc_number.to_s
    end

    # Returns the sanitized search query entered by the user, skipping
    # the default QuickSearch query filtering
    def sanitized_user_search_query
      # Need to use "to_str" as otherwise Japanese text isn't returned
      # properly
      sanitize(@q).to_str
    end

    def items_per_page
      allowed_values = [10, 25, 50, 100]
      allowed_values.each do |val|
        return val if @per_page <= val
      end
      allowed_values.last
    end

    # Strips RDF URI http://shcema.org/ prefix
    def plain_bib_type(bib)
      if(bib.type)
        bib.type.to_str[18..-1]
      end
    end

    def include_type?
      true
    end
  end
end
