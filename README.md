# Redis store with CAS for ActiveSupport

__`redis-activesupport-with-cas`__ provides a cache for __ActiveSupport__ including 'Compare and Swap' methods.
 
It is based on [redis-store](https://github.com/redis-store/redis-store) and may used with [Identity Cache](https://github.com/Shopify/identity_cache).

## Installation

```ruby
# Gemfile
gem 'redis-activesupport-with-cas'
```

## Usage

```ruby
ActiveSupport::Cache.lookup_store :redis_store_with_cas # { ... optional configuration ... }
```

### Usage with `IdentityCache`

Inside your environments configuration add following line:

```ruby
config.cache_store = :redis_store_with_cas, { :host => 'localhost', :port => 6379, :db => 0, :namespace => "data_cache", :expires_in => 15.minutes, :race_condition_ttl => 1}
IdentityCache.cache_backend = ActiveSupport::Cache.lookup_store(*Rails.configuration.cache_store)
```

## Running tests

```shell
gem install bundler
git clone https://git.alwin-it.de/ruby-redis/redis-activesupport-with-cas.git
cd redis-activesupport-with-cas
bundle install
bundle exec rake
```

## Copyright

2017 Rajko Albrecht, released under the MIT license
