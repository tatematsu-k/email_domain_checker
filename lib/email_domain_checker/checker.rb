# frozen_string_literal: true

require "email_address"
require_relative "normalizer"
require_relative "domain_validator"

module EmailDomainChecker
  class Checker
    attr_reader :email, :options

    def initialize(email, options = {})
      @email = Normalizer.normalize(email)
      @options = {
        validate_format: true,
        validate_domain: true,
        check_mx: true,
        check_a: false,
        timeout: 5
      }.merge(options)
      @domain_validator = DomainValidator.new(
        check_mx: @options[:check_mx],
        check_a: @options[:check_a],
        timeout: @options[:timeout]
      )
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
      @domain_validator.valid?(domain)
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

    def extract_domain
      parts = email.split("@", 2)
      return nil if parts.length != 2

      domain = parts[1].to_s.strip
      domain.empty? ? nil : domain
    end
  end
end

