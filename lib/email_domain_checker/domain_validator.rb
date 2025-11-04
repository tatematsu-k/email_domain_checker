# frozen_string_literal: true

require "resolv"

module EmailDomainChecker
  class DomainValidator
    attr_reader :options

    def initialize(options = {})
      @options = {
        check_mx: true,
        check_a: false,
        timeout: 5
      }.merge(options)
    end

    def valid?(domain)
      return false if domain.nil? || domain.empty?

      check_domain_records(domain)
    end

    private

    def check_domain_records(domain)
      if options[:check_mx]
        return false unless has_mx_record?(domain)
      end

      if options[:check_a]
        return false unless has_a_record?(domain)
      end

      true
    end

    def has_mx_record?(domain)
      resolver = Resolv::DNS.new
      resolver.timeouts = [options[:timeout]]

      begin
        mx_records = resolver.getresources(domain, Resolv::DNS::Resource::IN::MX)
        !mx_records.empty?
      rescue Resolv::ResolvError, Resolv::ResolvTimeout
        false
      end
    end

    def has_a_record?(domain)
      resolver = Resolv::DNS.new
      resolver.timeouts = [options[:timeout]]

      begin
        a_records = resolver.getresources(domain, Resolv::DNS::Resource::IN::A)
        !a_records.empty?
      rescue Resolv::ResolvError, Resolv::ResolvTimeout
        false
      end
    end
  end
end

