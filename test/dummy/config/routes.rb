Rails.application.routes.draw do
  mount QuickSearch::WorldCatDiscoveryApiSearcher::Engine => "/quick_search-world_cat_discovery_api_searcher"
end
