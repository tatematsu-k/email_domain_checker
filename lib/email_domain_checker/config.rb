# frozen_string_literal: true

require_relative "cache"

module EmailDomainChecker
  class Config
    DEFAULT_OPTIONS = {
      validate_format: true,
      validate_domain: true,
      check_mx: true,
      check_a: false,
      timeout: 5
    }.freeze

    DEFAULT_ROLE_ADDRESSES = %w[
      noreply no-reply
      admin administrator
      support help
      info contact
      sales marketing
      postmaster abuse
    ].freeze

    class << self
      attr_accessor :default_options, :test_mode, :cache_enabled, :cache_type, :cache_ttl, :cache_adapter, :cache_adapter_instance, :redis_client, :blacklist_domains, :whitelist_domains, :domain_checker, :reject_role_addresses, :role_addresses, :check_reputation_lists, :reputation_lists, :reputation_timeout, :reputation_fallback_action, :reputation_api_keys

      def configure(options = {}, &block)
        if block_given?
          config_instance = new
          block.call(config_instance)
          @default_options = DEFAULT_OPTIONS.merge(options)
          config_instance
        else
          @default_options = DEFAULT_OPTIONS.merge(options)
          new
        end
      end

      def reset
        @default_options = DEFAULT_OPTIONS.dup
        @test_mode = false
        @cache_enabled = true
        @cache_type = :memory
        @cache_ttl = 3600
        @cache_adapter = nil
        @cache_adapter_instance = nil
        @redis_client = nil
        @blacklist_domains = []
        @whitelist_domains = []
        @domain_checker = nil
        @reject_role_addresses = false
        @role_addresses = DEFAULT_ROLE_ADDRESSES.dup
        @check_reputation_lists = false
        @reputation_lists = []
        @reputation_timeout = 5
        @reputation_fallback_action = :allow
        @reputation_api_keys = {}
      end

      def test_mode=(value)
        @test_mode = value
      end

      def test_mode?
        @test_mode == true
      end

      def cache_enabled?
        @cache_enabled == true
      end

      def cache_adapter
        return nil unless cache_enabled?

        # If custom adapter instance is set, use it directly
        return @cache_adapter_instance if @cache_adapter_instance

        # Otherwise, create adapter from type
        @cache_adapter ||= Cache.create_adapter(type: cache_type, redis_client: redis_client)
      end

      def cache_adapter_instance=(instance)
        validate_cache_adapter_instance!(instance)
        @cache_adapter_instance = instance
        # Reset the auto-created adapter when custom instance is set
        @cache_adapter = nil
      end

      def cache_type=(value)
        @cache_type = value
        reset_cache_adapter_if_needed
      end

      def clear_cache
        cache_adapter&.clear
      end

      def clear_cache_for_domain(domain)
        return unless cache_enabled?

        adapter = cache_adapter
        return unless adapter

        # Clear both MX and A record cache entries
        dns_cache_keys_for_domain(domain).each do |key|
          adapter.delete(key)
        end
      end

      def reset_cache_adapter_if_needed
        # Reset cache adapter when changing cache type (unless custom instance is set)
        @cache_adapter = nil unless @cache_adapter_instance
        # Clear cache_adapter_instance if setting a type (Symbol or String), not a Class
        @cache_adapter_instance = nil if @cache_type.is_a?(Symbol) || @cache_type.is_a?(String)
      end

      def reset_cache_adapter_on_enabled_change(new_value, old_value)
        @cache_adapter = nil if new_value != old_value
      end

      def reset_cache_adapter_if_redis
        @cache_adapter = nil if @cache_type == :redis
      end

      def validate_cache_adapter_instance!(instance)
        unless instance.nil? || instance.is_a?(Cache::BaseAdapter)
          raise ArgumentError, "cache_adapter_instance must be an instance of EmailDomainChecker::Cache::BaseAdapter or nil"
        end
      end

      private

      def dns_cache_keys_for_domain(domain)
        keys = ["mx:#{domain}", "a:#{domain}"]
        # Add DNSBL cache keys if reputation lists are configured
        if check_reputation_lists && reputation_lists.is_a?(Array)
          reputation_lists.each do |dnsbl_host|
            keys << "dnsbl:#{dnsbl_host}:#{domain}"
          end
        end
        keys
      end
    end

    attr_accessor :test_mode, :cache_enabled, :cache_type, :cache_ttl, :cache_adapter_instance, :redis_client, :blacklist_domains, :whitelist_domains, :domain_checker, :reject_role_addresses, :role_addresses, :check_reputation_lists, :reputation_lists, :reputation_timeout, :reputation_fallback_action, :reputation_api_keys

    def initialize
      @test_mode = self.class.test_mode || false
      @cache_enabled = self.class.cache_enabled.nil? ? true : self.class.cache_enabled
      @cache_type = self.class.cache_type || :memory
      @cache_ttl = self.class.cache_ttl || 3600
      @cache_adapter_instance = self.class.cache_adapter_instance
      @redis_client = self.class.redis_client
      @blacklist_domains = self.class.blacklist_domains || []
      @whitelist_domains = self.class.whitelist_domains || []
      @domain_checker = self.class.domain_checker
      @reject_role_addresses = self.class.reject_role_addresses.nil? ? false : self.class.reject_role_addresses
      @role_addresses = self.class.role_addresses || DEFAULT_ROLE_ADDRESSES.dup
      @check_reputation_lists = self.class.check_reputation_lists.nil? ? false : self.class.check_reputation_lists
      @reputation_lists = self.class.reputation_lists || []
      @reputation_timeout = self.class.reputation_timeout || 5
      @reputation_fallback_action = self.class.reputation_fallback_action || :allow
      @reputation_api_keys = self.class.reputation_api_keys || {}
    end

    def test_mode=(value)
      @test_mode = value
      self.class.test_mode = value
    end

    def cache_enabled=(value)
      old_value = self.class.cache_enabled
      @cache_enabled = value
      self.class.cache_enabled = value
      # Reset cache adapter when enabling/disabling cache
      self.class.reset_cache_adapter_on_enabled_change(value, old_value)
    end

    def cache_type=(value)
      @cache_type = value
      self.class.cache_type = value
      self.class.reset_cache_adapter_if_needed
    end

    def cache_adapter_instance=(instance)
      self.class.validate_cache_adapter_instance!(instance)
      @cache_adapter_instance = instance
      self.class.cache_adapter_instance = instance
    end

    def cache_ttl=(value)
      @cache_ttl = value
      self.class.cache_ttl = value
    end

    def redis_client=(value)
      @redis_client = value
      self.class.redis_client = value
      # Reset cache adapter when changing redis client
      self.class.reset_cache_adapter_if_redis
    end

    def blacklist_domains=(value)
      @blacklist_domains = value || []
      self.class.blacklist_domains = value || []
    end

    def whitelist_domains=(value)
      @whitelist_domains = value || []
      self.class.whitelist_domains = value || []
    end

    def domain_checker=(value)
      @domain_checker = value
      self.class.domain_checker = value
    end

    def reject_role_addresses=(value)
      @reject_role_addresses = value
      self.class.reject_role_addresses = value
    end

    def role_addresses=(value)
      @role_addresses = value || DEFAULT_ROLE_ADDRESSES.dup
      self.class.role_addresses = value || DEFAULT_ROLE_ADDRESSES.dup
    end

    def check_reputation_lists=(value)
      @check_reputation_lists = value
      self.class.check_reputation_lists = value
    end

    def reputation_lists=(value)
      @reputation_lists = value || []
      self.class.reputation_lists = value || []
    end

    def reputation_timeout=(value)
      @reputation_timeout = value || 5
      self.class.reputation_timeout = value || 5
    end

    def reputation_fallback_action=(value)
      @reputation_fallback_action = value || :allow
      self.class.reputation_fallback_action = value || :allow
    end

    def reputation_api_keys=(value)
      @reputation_api_keys = value || {}
      self.class.reputation_api_keys = value || {}
    end

    reset
  end
end
