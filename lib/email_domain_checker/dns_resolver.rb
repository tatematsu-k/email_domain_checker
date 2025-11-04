# frozen_string_literal: true

require "resolv"

module EmailDomainChecker
  class DnsResolver
    attr_reader :timeout

    def initialize(timeout: 5)
      @timeout = timeout
    end

    def has_mx_record?(domain)
      check_dns_record(domain, Resolv::DNS::Resource::IN::MX)
    end

    def has_a_record?(domain)
      check_dns_record(domain, Resolv::DNS::Resource::IN::A)
    end

    private

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
  end
end

