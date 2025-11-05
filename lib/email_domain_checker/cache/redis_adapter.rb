# frozen_string_literal: true

require_relative "base_adapter"

module EmailDomainChecker
  module Cache
    # Redis cache adapter
    # Requires the 'redis' gem to be available
    class RedisAdapter < BaseAdapter
      def initialize(redis_client = nil)
        @redis = redis_client || create_default_redis_client
      end

      def get(key)
        value = @redis.get(key)
        return nil unless value

        # Parse JSON value
        JSON.parse(value)
      rescue JSON::ParserError, Redis::BaseError
        nil
      end

      def set(key, value, ttl: nil)
        json_value = JSON.generate(value)
        if ttl
          @redis.setex(key, ttl, json_value)
        else
          @redis.set(key, json_value)
        end
        value
      rescue Redis::BaseError
        # Silently fail if Redis is unavailable
        value
      end

      def delete(key)
        @redis.del(key)
      rescue Redis::BaseError
        # Silently fail if Redis is unavailable
      end

      def clear
        @redis.flushdb
      rescue Redis::BaseError
        # Silently fail if Redis is unavailable
      end

      def exists?(key)
        @redis.exists?(key)
      rescue Redis::BaseError
        false
      end

      private

      def create_default_redis_client
        require "redis"
        require "json"
        Redis.new
      rescue LoadError
        raise LoadError, "Redis gem is required for RedisAdapter. Please add 'gem \"redis\"' to your Gemfile."
      end
    end
  end
end
