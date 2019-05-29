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
        result.item_format = item_format(bib)
        @results_list << result
      end
      @results_list[0..@per_page - 1]
    end

    # Returns the item format for the given bib. Using a method so
    # it can be overridden by subclasses.
    def item_format(bib)
      ItemFormats.item_format(bib) || 'other'
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
  end

  # Provides a mapping of WorldCat Bibliographic book formats
  # to simple and more normalized types
  class ItemFormats
    # Map of Bibligraphic book_formats to item format
    @item_formats = {
      'http://schema.org/Hardcover' => 'book',
      'http://bibliograph.net/LargePrintBook' => 'book',
      'http://schema.org/Paperback' => 'book',
      'http://bibliograph.net/PrintBook' => 'book',
      'http://bibliograph.net/AudioBook' => 'audio_book',
      'http://schema.org/EBook' => 'e_book'
    }

    # Returns string representing the item format for the given
    # Bibliographic record
    def self.item_format(bib)
      book_format = bib.book_format.to_s

      @item_formats[book_format] || 'other'
    end
  end
end
