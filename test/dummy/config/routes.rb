Rails.application.routes.draw do
  mount QuickSearchWorldCatDiscoveryApiSearcher::Engine => "/quick_search-world_cat_discovery_api_searcher"
end
