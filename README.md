# quick_search-world_cat_discovery_api_searcher

WorldCat Discovery API searcher for NCSU Quick Search

## Installation

Include the searcher gem in your Gemfile:

```
gem 'quick_search-world_cat_discovery_api_searcher'
```

Run bundle install:

```
bundle install
```

This gem provides two separate WorldCat Discovery searchers:

* world_cat_discovery_api_searcher: A searcher that queries WorldCat Discovery
  for all item types
* world_cat_discovery_api_article_searcher: A searcher that limits the
  WorldCat Discovery query to articles and book chapters

The world_cat_discovery_api_article_searcher has special handling to return a
direct link to the article (instead of to the WorldCat catalog entry), where
possible.

## Searcher Configuration

### world_cat_discovery_api_searcher

In your search application:

1) Add the "world_cat_discovery_api" searcher to config/quick_search_config.yml

2) Copy the config/world_cat_discovery_api_config.yml file into the
   config/searchers/ directory and fill out the
   values are appropriate.

3) Include in your Search Results page

```
<%= render_module(@world_cat_discovery_api, 'world_cat_discovery_api') %>
```

### world_cat_discovery_api_article

1) Add the "world_cat_discovery_api_article" searcher to config/quick_search_config.yml

2) Copy the config/world_cat_discovery_api_article_config.yml file into the
   config/searchers/ directory and fill out the
   values are appropriate.

3) Include in your Search Results page

```
<%= render_module(@world_cat_discovery_api_article, 'world_cat_discovery_api_article') %>
```

## Additional Result Information

The searchers return the following additional information about each item:

* "item_format"
  * The "world_cat_discovery_api" searcher will return  one of the following:
    * "audio_book"
    * "book"
    * "e_book"
    * "other" - Default if the type cannot be determined
  * The "world_cat_discovery_api_article" searcher always returns "article"
