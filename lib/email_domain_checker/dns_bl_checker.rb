# frozen_string_literal: true

require "resolv"
require_relative "config"

module EmailDomainChecker
  class DnsBlChecker
    attr_reader :timeout, :reputation_lists, :fallback_action

    def initialize(timeout: 5, reputation_lists: [], fallback_action: :allow, cache: nil, api_keys: {})
      @timeout = timeout
      @reputation_lists = reputation_lists || []
      @fallback_action = fallback_action
      @cache = cache
      @api_keys = api_keys || {}
    end

    # Check if domain is listed in any configured DNSBL
    # @param domain [String] Domain name to check
    # @return [Boolean] true if domain is NOT listed (safe), false if listed (unsafe)
    def safe?(domain)
      return true if domain.nil? || domain.empty?
      return true if reputation_lists.empty?

      # Check all reputation lists in parallel
      results = check_all_lists(domain)
      results.all? { |listed| !listed }
    end

    # Check if domain is listed in any configured DNSBL
    # @param domain [String] Domain name to check
    # @return [Boolean] true if domain is listed (unsafe), false if not listed (safe)
    def listed?(domain)
      !safe?(domain)
    end

    # Check a specific domain against a specific DNSBL service
    # @param domain [String] Domain name to check
    # @param dnsbl_host [String] DNSBL service hostname (e.g., "zen.spamhaus.org")
    # @return [Boolean] true if domain is listed, false if not listed or on error
    def listed_in?(domain, dnsbl_host)
      return false if domain.nil? || domain.empty? || dnsbl_host.nil? || dnsbl_host.empty?

      # Build DNSBL query: reverse domain and append DNSBL host
      # e.g., "example.com" -> "com.example.zen.spamhaus.org"
      query = build_dnsbl_query(domain, dnsbl_host)
      cache_key = "dnsbl:#{dnsbl_host}:#{domain}"

      begin
        result = if cache
                   cache.with(cache_key, ttl: cache_ttl) do
                     perform_dnsbl_lookup(query)
                   end
                 else
                   perform_dnsbl_lookup(query)
                 end

        result
      rescue Resolv::ResolvTimeout, StandardError => e
        # On error, use fallback action
        handle_lookup_error(e)
      end
    end

    private

    def check_all_lists(domain)
      return [] if reputation_lists.empty?

      # Check all lists in parallel using threads
      threads = reputation_lists.map do |dnsbl_host|
        Thread.new do
          begin
            listed_in?(domain, dnsbl_host)
          rescue StandardError
            handle_lookup_error($ERROR_INFO)
          end
        end
      end

      threads.map(&:value)
    end

    def build_dnsbl_query(domain, dnsbl_host)
      # Reverse domain parts: "example.com" -> "com.example"
      reversed = domain.split(".").reverse.join(".")

      # If API key is configured for this DNSBL service, prepend it as subdomain
      # e.g., "zen.spamhaus.org" with API key "abc123" -> "abc123.zen.spamhaus.org"
      host_with_key = if api_key = get_api_key(dnsbl_host)
                        # Insert API key as subdomain before the first part of hostname
                        parts = dnsbl_host.split(".")
                        "#{api_key}.#{parts.join(".")}"
                      else
                        dnsbl_host
                      end

      "#{reversed}.#{host_with_key}"
    end

    def get_api_key(dnsbl_host)
      # Check instance variable first, then Config
      api_keys = @api_keys || Config.reputation_api_keys || {}
      api_keys[dnsbl_host] || api_keys[dnsbl_host.to_sym]
    end

    def perform_dnsbl_lookup(query)
      resolver = create_resolver

      begin
        # Query for A record
        # If A record exists, domain is listed
        records = resolver.getresources(query, Resolv::DNS::Resource::IN::A)
        !records.empty?
      rescue Resolv::ResolvError
        # NXDOMAIN or other DNS error means not listed
        false
      rescue Resolv::ResolvTimeout => e
        # Timeout - use fallback action
        raise e
      end
    end

    def create_resolver
      resolver = Resolv::DNS.new
      resolver.timeouts = [timeout]
      resolver
    end

    def handle_lookup_error(error)
      case fallback_action
      when :reject
        # On error, treat as listed (unsafe)
        true
      when :allow
        # On error, treat as not listed (safe)
        false
      else
        # Default to allow
        false
      end
    end

    def cache
      # Use instance variable if set, otherwise try to get from Config
      return @cache if defined?(@cache) && !@cache.nil?
      return Config.cache_adapter if Config.cache_enabled?
    end

    def cache_ttl
      Config.cache_ttl
    end
  end
end
