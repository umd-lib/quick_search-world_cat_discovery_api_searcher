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
        result.author = bib.author.try(:name)
        result.date = bib.date_published
        @results_list << result
      end
      @results_list[0..@per_page - 1]
    end

    def total
      @response.total_results
    end

    def query_params
      {
        q: http_request_queries['not_escaped'],
        startIndex: @offset,
        itemsPerPage: items_per_page
      }
    end

    def loaded_link
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG['loaded_link'] +
        http_request_queries['uri_escaped']
    end

    def item_link(bib)
      loaded_link + '#/oclc/' + bib.oclc_number.to_s
    end

    def items_per_page
      allowed_values = [10, 25, 50, 100]
      allowed_values.each do |val|
        return val if @per_page <= val
      end
      allowed_values.last
    end
  end
end
