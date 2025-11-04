# frozen_string_literal: true

require "email_address"
require "resolv"

module EmailDomainChecker
  class Checker
    attr_reader :email, :options

    def initialize(email, options = {})
      @email = email.to_s.strip
      @options = {
        validate_format: true,
        validate_domain: true,
        check_mx: true,
        check_a: false,
        timeout: 5
      }.merge(options)
    end

    def valid?
      return false if email.empty?

      format_valid? && domain_valid?
    end

    def format_valid?
      return true unless options[:validate_format]

      EmailAddress.valid?(email)
    end

    def domain_valid?
      return true unless options[:validate_domain]

      domain = extract_domain
      return false if domain.nil? || domain.empty?

      check_domain_records(domain)
    end

    def normalized_email
      return nil unless format_valid?

      email_address = EmailAddress.new(email)
      email_address.normalized
    end

    def canonical_email
      return nil unless format_valid?

      email_address = EmailAddress.new(email)
      email_address.canonical
    end

    private

    def extract_domain
      parts = email.split("@", 2)
      return nil if parts.length != 2

      domain = parts[1].to_s.strip
      domain.empty? ? nil : domain
    end

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

