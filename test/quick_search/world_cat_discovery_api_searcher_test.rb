# frozen_string_literal: true

require 'test_helper'

module QuickSearch
  class WorldCatDiscoveryApiSearcher
    # DatabaseFinderSearch tests
    class Test < ActiveSupport::TestCase
      test 'truth' do
        assert_kind_of Module, QuickSearch::WorldCatDiscoveryApiSearcher
      end
    end
  end
end
