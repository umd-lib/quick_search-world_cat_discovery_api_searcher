# Try to load a local version of the config file if it exists - expected to be in quicksearch_root/config/searchers/<my_searcher_name>_config.yml
 
if File.exists?(File.join(Rails.root, '/config/searchers/world_cat_discovery_api_config.yml'))
  config_file = File.join Rails.root, '/config/searchers/world_cat_discovery_api_config.yml'
else
  # otherwise load the default config file
  config_file = File.expand_path('../../world_cat_discovery_api_config.yml', __FILE__)
end
QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]