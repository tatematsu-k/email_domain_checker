# frozen_string_literal: true

module EmailDomainChecker
  module Cache
    # Base class for cache adapters
    # All cache adapters must implement these methods
    class BaseAdapter
      # Get cached value for a key
      # @param key [String] cache key
      # @return [Object, nil] cached value or nil if not found
      def get(key)
        raise NotImplementedError, "Subclasses must implement #get"
      end

      # Set a value in cache
      # @param key [String] cache key
      # @param value [Object] value to cache
      # @param ttl [Integer, nil] time to live in seconds (nil for no expiration)
      # @return [void]
      def set(key, value, ttl: nil)
        raise NotImplementedError, "Subclasses must implement #set"
      end

      # Delete a key from cache
      # @param key [String] cache key
      # @return [void]
      def delete(key)
        raise NotImplementedError, "Subclasses must implement #delete"
      end

      # Clear all cache entries
      # @return [void]
      def clear
        raise NotImplementedError, "Subclasses must implement #clear"
      end

      # Check if a key exists in cache
      # @param key [String] cache key
      # @return [Boolean] true if key exists
      def exists?(key)
        get(key) != nil
      end

      # Fetch value from cache or execute block and cache the result
      # Similar to Rails.cache.fetch
      # @param key [String] cache key
      # @param ttl [Integer, nil] time to live in seconds (nil for no expiration)
      # @param force [Boolean] if true, always execute block and update cache
      # @yield Block to execute when cache miss
      # @return [Object] cached value or block result
      def with(key, ttl: nil, force: false, &block)
        raise ArgumentError, "Block is required" unless block_given?

        # Return cached value if not forcing and cache exists
        unless force
          return get(key) if exists?(key)
        end

        # Execute block and cache the result
        # Rails.cache.fetch also caches nil values, so we do the same
        value = yield
        set(key, value, ttl: ttl)
        value
      end
    end
  end
end
