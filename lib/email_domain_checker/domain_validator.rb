# frozen_string_literal: true

require_relative "dns_resolver"
require_relative "config"

module EmailDomainChecker
  class DomainValidator
    attr_reader :options, :dns_resolver

    def initialize(options = {})
      @options = {
        check_mx: true,
        check_a: false,
        timeout: 5
      }.merge(options)
      @dns_resolver = DnsResolver.new(timeout: @options[:timeout])
    end

    def valid?(domain)
      return false if domain.nil? || domain.empty?

      # Skip DNS checks if test mode is enabled
      return true if Config.test_mode?

      check_domain_records(domain)
    end

    private

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
