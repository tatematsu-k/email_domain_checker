# frozen_string_literal: true

require_relative "normalizer"
require_relative "domain_validator"
require_relative "email_address_adapter"

module EmailDomainChecker
  class Checker
    attr_reader :email, :options

    def initialize(email, options = {})
      @email = Normalizer.normalize(email)
      @options = Config.default_options.merge(options)
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

      email_adapter.valid?
    end

    def domain_valid?
      return true unless options[:validate_domain]

      domain = extract_domain
      @domain_validator.valid?(domain)
    end

    def normalized_email
      return nil unless format_valid?

      email_adapter.normalized
    end

    def canonical_email
      return nil unless format_valid?

      email_adapter.canonical
    end

    def redacted_email
      return nil unless format_valid?

      email_adapter.redacted
    end

    private

    def email_adapter
      @email_adapter ||= EmailAddressAdapter.new(email)
    end

    def extract_domain
      parts = email.split("@", 2)
      return nil if parts.length != 2

      domain = parts[1].to_s.strip
      domain.empty? ? nil : domain
    end
  end
end
