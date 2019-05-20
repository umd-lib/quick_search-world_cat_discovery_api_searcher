# frozen_string_literal: true

module QuickSearch
  # Helper class for returning the item format from WorldCat Discovery API
  # Bibliographic records
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
