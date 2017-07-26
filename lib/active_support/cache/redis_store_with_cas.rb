require 'active_support'
require 'redis-store-with-cas'
require 'active_support/cache/redis_store'

module ActiveSupport
  module Cache
    module RedisStoreCas

      attr_accessor :read_only

      def cas name,options=nil
        options = merged_options(options)
        key = normalize_key(name, options)
        instrument(:cas, name, options) do
          ttl = cas_expiration options
          @data.cas(key,ttl) do |entry|
            value = yield entry.value
            break true if read_only
            options[:raw].present? ? value : Entry.new(value, options)
          end
        end
      end

      def cas_muli

      end

      private

      def cas_expiration(options)
        if options[:expires_in].present? && options[:race_condition_ttl].present? && options[:raw].blank?
          options[:expires_in].to_f + options[:race_condition_ttl].to_f
        else
          nil
        end
      end

    end

    class RedisStoreWithCas < RedisStore

      def initialize(*adresses)
        super adresses
        check_and_extend_cas
      end

      def candocas?
        @data.is_a?(Redis::Store) && @data.respond_to?(:cas)
      end

      private

      def check_and_extend_cas
        extend RedisStoreCas if candocas?
      end

    end
  end
end
