# Try to load a local version of the config file if it exists - expected to be in quicksearch_root/config/searchers/<my_searcher_name>_config.yml

# Returns the value for the given key, first checking the WorldCat Discovery API
# config file, and then falling back to the WorldCat Discovery API Article
# configuration, if not found.
def get_common_configuration(key)
  QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG[key] ||
  QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG[key]
end

# WorldCat Discovery API searcher configuration
if File.exists?(File.join(Rails.root, '/config/searchers/world_cat_discovery_api_config.yml'))
  config_file = File.join Rails.root, '/config/searchers/world_cat_discovery_api_config.yml'
else
  # otherwise load the default config file
  config_file = File.expand_path('../../world_cat_discovery_api_config.yml', __FILE__)
end
QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]

# WorldCat Discovery API Article searcher configuration
if File.exists?(File.join(Rails.root, '/config/searchers/world_cat_discovery_api_article_config.yml'))
  config_file = File.join Rails.root, '/config/searchers/world_cat_discovery_api_article_config.yml'
else
  # otherwise load the default config file
  config_file = File.expand_path('../../world_cat_discovery_api_article_config.yml', __FILE__)
end
QuickSearch::Engine::WORLD_CAT_DISCOVERY_API_ARTICLE_CONFIG = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]


# Get the configuration values
key = get_common_configuration('wskey')
secret = get_common_configuration('secret')
authenticating_institution_id = get_common_configuration('authenticatingInstitutionId')
context_institution_id = get_common_configuration('contextInstitutionId')

# Create WSKey object
wskey = OCLC::Auth::WSKey.new(key, secret, :services => ['WorldCatDiscoveryAPI'])

# Configure WorldCat Discovery gem
WorldCat::Discovery.configure(wskey, authenticating_institution_id, context_institution_id)

# Set SSL version to TLSv1_2. Otherwise SSLv3 is used as default and results in a handshake error
# Error will be triggered at https://github.com/OCLC-Developer-Network/oclc-auth-ruby/blob/master/lib/oclc/auth/access_token.rb#L58
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1_2'
