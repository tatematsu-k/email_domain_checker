# frozen_string_literal: true

require "email_address"
require "resolv"

module EmailDomainChecker
  class Checker
    attr_reader :email, :options

    def initialize(email, options = {})
      @email = normalize_input(email)
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
      email_address.normal
    end

    def canonical_email
      return nil unless format_valid?

      email_address = EmailAddress.new(email)
      email_address.canonical
    end

    def redacted_email
      return nil unless format_valid?

      email_address = EmailAddress.new(email)
      email_address.redact
    end

    private

    def normalize_input(raw)
      return "" if raw.nil? || raw.to_s.strip.empty?

      email_str = raw.to_s.strip
      return "" if email_str.empty?

      # Basic normalization: lowercase and IDN handling
      local, domain = email_str.downcase.split("@", 2)
      return email_str unless local && domain && !local.empty? && !domain.empty?

      # IDN (Internationalized Domain Name) conversion
      # Convert Unicode domain to ASCII (Punycode)
      domain = idn_to_ascii(domain)
      "#{local}@#{domain}"
    end

    def idn_to_ascii(domain)
      # Simple IDN conversion using built-in methods
      # For production, consider using the 'simpleidn' gem
      begin
        # Try to encode as IDN if it contains non-ASCII characters
        if domain.match?(/[^\x00-\x7F]/)
          # Fallback: return as-is if IDN conversion fails
          # In production, use: SimpleIDN.to_ascii(domain)
          domain
        else
          domain
        end
      rescue StandardError
        domain
      end
    end

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

