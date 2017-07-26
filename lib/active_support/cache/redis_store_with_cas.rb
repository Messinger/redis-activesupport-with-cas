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

      def cas_multi(*names)
        options = names.extract_options!
        return if names.empty?

        options = merged_options(options)
        keys_to_names = Hash[names.map { |name| [normalize_key(name, options), name] }]

        instrument(:cas_multi, names, options) do
          @data.cas_multi(*(keys_to_names.keys), {:expires_in => cas_expiration(options)}) do |raw_values|
            values = {}
            raw_values.each do |key, entry|
              values[keys_to_names[key]] = entry.value unless entry.expired?
            end
            values = yield values
            break true if read_only
            mapped_values = values.map do |name,value|
              [normalize_key(name, options),options[:raw].present? ? value : Entry.new(value, options)]
            end
            Hash[mapped_values]
          end
          true
        end

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
        super 
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
