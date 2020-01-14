# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'quick_search/world_cat_discovery_api_searcher/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'quick_search-world_cat_discovery_api_searcher'
  s.version     = QuickSearchWorldCatDiscoveryApiSearcher::VERSION
  s.authors     = ['UMD Libraries']
  s.email       = ['lib-ssdr@umd.edu']
  s.homepage    = 'https://www.lib.umd.edu/'
  s.summary     = 'WorldCat Discovery API searcher for NCSU Quick Search.'
  s.description = 'WorldCat Discovery API searcher for NCSU Quick Search.'
  s.license     = 'Apache 2.0'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'quick_search-core', '~> 0'
  s.add_dependency 'umd_open_url'
  s.add_dependency 'worldcat-discovery', '~> 1.2.0.2'

  s.add_development_dependency 'rubocop', '= 0.78.0'
  s.add_development_dependency 'rubocop-rails'
  # sqlite3 loaded for testing with the "dummy" application
  s.add_development_dependency 'sqlite3'

  # The "rdf-vocab" gem is need by the "spira" gem loaded by
  # "worldcat-discovery", for use in testing. Without this
  # gem, "rails test" will fail.
  s.add_development_dependency 'rdf-vocab'
end
