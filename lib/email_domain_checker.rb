# frozen_string_literal: true

require_relative "email_domain_checker/version"
require_relative "email_domain_checker/config"
require_relative "email_domain_checker/normalizer"
require_relative "email_domain_checker/dns_resolver"
require_relative "email_domain_checker/domain_validator"
require_relative "email_domain_checker/email_address_adapter"
require_relative "email_domain_checker/checker"

module EmailDomainChecker
  class Error < StandardError; end

  # Convenience method for quick validation
  def self.valid?(email, options = {})
    Checker.new(email, options).valid?
  end

  # Convenience method for format validation only
  def self.format_valid?(email)
    Checker.new(email, validate_domain: false).format_valid?
  end

  # Convenience method for domain validation only
  def self.domain_valid?(email, options = {})
    Checker.new(email, validate_format: false, **options).domain_valid?
  end

  # Convenience method for normalization
  def self.normalize(email)
    Normalizer.normalize(email)
  end

  # Configure default options
  def self.configure(options = {})
    Config.configure(options)
  end
end
