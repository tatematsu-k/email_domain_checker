# frozen_string_literal: true

require_relative "base_adapter"

module EmailDomainChecker
  module Cache
    # In-memory cache adapter using a simple hash
    # This is the default cache adapter when Redis is not available
    class MemoryAdapter < BaseAdapter
      def initialize
        @store = {}
        @expirations = {}
        @nil_keys = {} # Track keys that have nil values
      end

      def get(key)
        # Check if key exists (including nil values)
        return nil unless @store.key?(key) || @nil_keys.key?(key)

        # Check if expired
        if @expirations.key?(key) && Time.now > @expirations[key]
          delete(key)
          return nil
        end

        # Return nil if it was explicitly cached, otherwise return stored value
        return nil if @nil_keys.key?(key)

        @store[key]
      end

      def set(key, value, ttl: nil)
        if value.nil?
          # Store nil separately to distinguish from "not cached"
          @nil_keys[key] = true
          @store.delete(key)
        else
          @store[key] = value
          @nil_keys.delete(key)
        end

        if ttl
          @expirations[key] = Time.now + ttl
        else
          @expirations.delete(key)
        end
        value
      end

      def delete(key)
        @store.delete(key)
        @nil_keys.delete(key)
        @expirations.delete(key)
      end

      def clear
        @store.clear
        @nil_keys.clear
        @expirations.clear
      end

      def exists?(key)
        return false unless @store.key?(key) || @nil_keys.key?(key)

        # Check if expired
        if @expirations.key?(key) && Time.now > @expirations[key]
          delete(key)
          return false
        end

        true
      end

      # Get cache size (for debugging/monitoring)
      def size
        # Clean expired entries first
        clean_expired
        @store.size + @nil_keys.size
      end

      private

      def clean_expired
        now = Time.now
        @expirations.each do |key, expiration|
          delete(key) if now > expiration
        end
      end
    end
  end
end
