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
    # Map of WorldCat types to item format
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
      'http://www.productontology.org/id/Thesis' => 'thesis',

      # Map of Bibligraphic genres to item format
      'Streaming audio' => 'e_music',
      'Downloadable audio file' => 'e_music',
      'Internet videos' => 'e_video',
      'Streaming videos' => 'e_video'
    }.transform_keys(&:downcase)

    # Weight the formats, where more specific formats have a greater weight.
    @format_weights = {
      'archival_material' => 10,
      'article' => 5,
      'audio_book' => 10,
      'book' => 1,
      'cd' => 5,
      'computer_file' => 10,
      'dvd' => 5,
      'e_book' => 10,
      'e_music' => 10,
      'e_video' => 10,
      'image' => 10,
      'journal' => 10,
      'lp' => 5,
      'map' => 10,
      'newspaper' => 10,
      'score' => 10,
      'thesis' => 10
    }

    # Returns string representing the item format for the given
    # Bibliographic record
    def self.item_format(bib) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      all_types = []

      # Retrieve all the possible types from the bib record
      all_types << bib.type
      all_types << bib.types
      all_types << bib.book_format
      all_types << bib.genres

      best_type = WorldCat::Discovery::Bib.choose_best_type(bib)
      all_types << best_type.format if best_type.is_a? WorldCat::Discovery::MusicAlbum

      # Remove any nil entries, and turn any arrays into individual elements
      all_types = all_types.flatten.compact

      # Convert all_types to array of item formats
      found_formats = all_types.map { |t| @item_formats[t.to_s.downcase] }.compact

      # Assign a weight to each item format in the array
      weighted_found_formats = found_formats.map { |f| { field: f, weight: @format_weights[f] } }

      # Find the item format with the highest weight, also sort by name to
      # ensure a consistent result in case weights are tied.
      max_weight_format = weighted_found_formats.sort_by { |f| [f[:weight], f[:field]] }.reverse.first

      # Retrieve the item format (if one exists)
      item_format = max_weight_format[:field] if max_weight_format

      # Return either the item_format or default_format
      default_format = 'other'
      item_format || default_format
    end
  end
end
