require 'bundler/setup'
require 'minitest/autorun'
require 'mocha/setup'
require 'active_support'
require 'active_support/cache/redis_store_with_cas'

puts "Testing against ActiveSupport v.#{ActiveSupport::VERSION::STRING}"