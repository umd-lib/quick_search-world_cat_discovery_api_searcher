# frozen_string_literal: true

module QuickSearch
  # QuickSearch searcher for WorldCat
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
      ItemFormats.item_format(bib)
    end

    def total
      @response.total_results
    end

    def query_params
      {
        q: http_request_queries['not_escaped'],
        startIndex: @offset,
        itemsPerPage: items_per_page,
        sortBy: 'library_plus_relevance'
      }
    end

    def loaded_link
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG['loaded_link'] +
        percent_encoded_raw_user_search_query
    end

    def item_link(bib)
      QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG['url_link'] +
        bib.oclc_number.to_s
    end

    # Returns the percent-encoded search query entered by the user, skipping
    # the default QuickSearch query filtering
    def percent_encoded_raw_user_search_query
      CGI.escape(@q)
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
      'http://purl.org/library/ArchiveMaterial' => 'archival_material',
      'http://schema.org/Article' => 'article',
      'http://bibliograph.net/AudioBook' => 'audio_book',
      'http://schema.org/Book' => 'book',
      'http://schema.org/Hardcover' => 'book',
      'http://bibliograph.net/LargePrintBook' => 'book',
      'http://schema.org/Paperback' => 'book',
      'http://bibliograph.net/PrintBook' => 'book',
      'http://bibliograph.net/CD' => 'cd',
      'http://www.productontology.org/id/Compact_Disc' => 'cd',
      'http://bibliograph.net/ComputerFile' => 'computer_file',
      'http://bibliograph.net/DVD' => 'dvd',
      'http://www.productontology.org/doc/DVD' => 'dvd',
      'http://schema.org/EBook' => 'e_book',
      'http://bibliograph.net/Image' => 'image',
      'http://www.productontology.org/doc/Image' => 'image',
      'http://purl.org/library/VisualMaterial' => 'image',
      'http://schema.org/Periodical' => 'journal',
      'http://purl.org/library/Serial' => 'journal',
      'http://bibliograph.net/LPRecord' => 'lp',
      'http://www.productontology.org/id/LP_record' => 'lp',
      'http://bibliograph.net/Atlas' => 'map',
      'http://schema.org/Map' => 'map',
      'http://bibliograph.net/Newspaper' => 'newspaper',
      'http://bibliograph.net/MusicScore' => 'score',
      'http://purl.org/ontology/mo/Score' => 'score',
      'http://www.productontology.org/id/Sheet_music' => 'score',
      'http://bibliograph.net/Thesis' => 'thesis',
      'http://www.productontology.org/id/Thesis' => 'thesis'
    }

    # Map of Bibligraphic genres to item format
    @genres = {
      'Streaming audio' => 'e_music',
      'Downloadable audio file' => 'e_music',
      'Internet videos' => 'e_video',
      'Streaming videos' => 'e_video'
    }

    # Returns string representing the item format for the given
    # Bibliographic record
    def self.item_format(bib) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/LineLength
      best_type = WorldCat::Discovery::Bib.choose_best_type(bib)
      type = bib.type

      types = bib.types
      if type.to_s == 'http://schema.org/Book'
        # Remove Book type from types, if present, as
        # the array may have a more specific type
        types = bib.types - [type]
      end

      book_format = bib.book_format
      genres = bib.genres

      if best_type.is_a? WorldCat::Discovery::MusicAlbum
        format = best_type.format

        if format.present?
          music_format = format.map { |f| @item_formats[f.to_s] }.compact.first
          return music_format
        end
      end

      type_item_format = @item_formats[type.to_s]
      types_item_format = types.map { |t| @item_formats[t.to_s] }.compact.first
      book_item_format = @item_formats[book_format.to_s]
      genres_item_format = genres.map { |g| @genres[g] }.compact.first

      # Order is important -- we are trying to return the most specific type
      return book_item_format if book_item_format
      return types_item_format if types_item_format
      return type_item_format if type_item_format
      return genres_item_format if genres_item_format

      default_format = 'other'
      # Return default
      default_format
    end
  end
end
