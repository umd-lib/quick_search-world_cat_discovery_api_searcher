$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "quick_search/world_cat_discovery_api_searcher/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "quick_search-world_cat_discovery_api_searcher"
  s.version     = QuickSearch::WorldCatDiscoveryApiSearcher::VERSION
  s.authors     = ["Mohamed Abdul Rasheed"]
  s.email       = ["mohideen@umd.edu"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of QuickSearch::WorldCatDiscoveryApiSearcher."
  s.description = "TODO: Description of QuickSearch::WorldCatDiscoveryApiSearcher."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.5"

  s.add_development_dependency "sqlite3"
end
