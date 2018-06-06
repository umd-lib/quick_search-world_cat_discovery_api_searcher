module QuickSearch
  module WorldCatDiscoveryApiSearcher
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
