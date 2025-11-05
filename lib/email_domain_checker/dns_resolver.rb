# frozen_string_literal: true

require "resolv"
require_relative "config"

module EmailDomainChecker
  class DnsResolver
    attr_reader :timeout

    def initialize(timeout: 5, cache: nil)
      @timeout = timeout
      @cache = cache
    end

    def has_mx_record?(domain)
      has_record?(domain, "mx", Resolv::DNS::Resource::IN::MX)
    end

    def has_a_record?(domain)
      has_record?(domain, "a", Resolv::DNS::Resource::IN::A)
    end

    private

    def has_record?(domain, record_type, resource_type)
      cache_key = "#{record_type}:#{domain}"
      if cache
        cache.with(cache_key, ttl: cache_ttl) do
          check_dns_record(domain, resource_type)
        end
      else
        check_dns_record(domain, resource_type)
      end
    end

    def check_dns_record(domain, resource_type)
      resolver = create_resolver

      begin
        records = resolver.getresources(domain, resource_type)
        !records.empty?
      rescue Resolv::ResolvError, Resolv::ResolvTimeout
        false
      end
    end

    def create_resolver
      resolver = Resolv::DNS.new
      resolver.timeouts = [timeout]
      resolver
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
