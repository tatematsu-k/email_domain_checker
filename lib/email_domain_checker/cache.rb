# frozen_string_literal: true

require_relative "cache/base_adapter"
require_relative "cache/memory_adapter"

# Conditionally load Redis adapter if available
begin
  require "redis"
  require "json"
  require_relative "cache/redis_adapter"
rescue LoadError
  # Redis is not available, skip Redis adapter
end

module EmailDomainChecker
  module Cache
    # Factory method to create cache adapter based on configuration
    #
    # @param type [Symbol, Class, Object] Cache adapter type, class, or instance
    #   - Symbol: :memory or :redis
    #   - Class: A custom adapter class (must inherit from BaseAdapter)
    #   - Object: A custom adapter instance (must be an instance of BaseAdapter)
    # @param redis_client [Redis, nil] Redis client instance (only used for :redis type)
    # @return [BaseAdapter] Cache adapter instance
    def self.create_adapter(type: :memory, redis_client: nil)
      # If type is already an adapter instance, return it
      return type if type.is_a?(BaseAdapter)

      # If type is a Class, instantiate it
      if type.is_a?(Class)
        unless type < BaseAdapter
          raise ArgumentError, "Custom cache adapter class must inherit from EmailDomainChecker::Cache::BaseAdapter"
        end
        return type.new
      end

      # Handle symbol types
      case type.to_sym
      when :memory
        MemoryAdapter.new
      when :redis
        if defined?(RedisAdapter)
          RedisAdapter.new(redis_client)
        else
          # Fallback to memory if Redis is not available
          warn "Redis adapter requested but 'redis' gem is not available. Falling back to memory cache."
          MemoryAdapter.new
        end
      else
        raise ArgumentError, "Unknown cache adapter type: #{type}. Available: :memory, :redis, or a custom BaseAdapter class/instance"
      end
    end
  end
end
