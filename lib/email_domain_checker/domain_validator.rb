# frozen_string_literal: true

require_relative "dns_resolver"
require_relative "dns_bl_checker"
require_relative "config"

module EmailDomainChecker
  class DomainValidator
    attr_reader :options, :dns_resolver, :dns_bl_checker

    def initialize(options = {})
      @options = {
        check_mx: true,
        check_a: false,
        timeout: 5
      }.merge(options)
      cache = Config.cache_enabled? ? Config.cache_adapter : nil
      @dns_resolver = DnsResolver.new(timeout: @options[:timeout], cache: cache)
      @dns_bl_checker = DnsBlChecker.new(
        timeout: Config.reputation_timeout || @options[:timeout],
        reputation_lists: Config.reputation_lists || [],
        fallback_action: Config.reputation_fallback_action || :allow,
        cache: cache,
        api_keys: Config.reputation_api_keys || {}
      )
    end

    def valid?(domain)
      return false if domain.nil? || domain.empty?

      # Check whitelist first (if configured)
      unless Config.whitelist_domains.nil? || Config.whitelist_domains.empty?
        return whitelisted?(domain)
      end

      # Check blacklist
      return false if blacklisted?(domain)

      # Check custom domain checker
      if Config.domain_checker
        custom_result = Config.domain_checker.call(domain)
        return false unless custom_result
      end

      # Skip DNS checks if test mode is enabled
      return true if Config.test_mode?

      # Check DNSBL reputation lists if enabled
      if Config.check_reputation_lists
        return false unless dns_bl_checker.safe?(domain)
      end

      check_domain_records(domain)
    end

    private

    def whitelisted?(domain)
      return false if Config.whitelist_domains.nil? || Config.whitelist_domains.empty?

      Config.whitelist_domains.any? do |pattern|
        matches_pattern?(domain, pattern)
      end
    end

    def blacklisted?(domain)
      return false if Config.blacklist_domains.nil? || Config.blacklist_domains.empty?

      Config.blacklist_domains.any? do |pattern|
        matches_pattern?(domain, pattern)
      end
    end

    def matches_pattern?(domain, pattern)
      case pattern
      when Regexp
        pattern.match?(domain)
      when String
        pattern == domain
      else
        false
      end
    end

    def check_domain_records(domain)
      if options[:check_mx]
        return false unless dns_resolver.has_mx_record?(domain)
      end

      if options[:check_a]
        return false unless dns_resolver.has_a_record?(domain)
      end

      true
    end
  end
end
