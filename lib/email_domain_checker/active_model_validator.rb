# frozen_string_literal: true

require "active_model"

require_relative "checker"
require_relative "normalizer"

module EmailDomainChecker
  # ActiveModel validator for email domain checking
  #
  # Usage:
  #   class User < ActiveRecord::Base
  #     validates :email, domain_check: { check_mx: true, timeout: 3 }, normalize: true
  #   end
  #
  # Options:
  #   - domain_check: Hash of options for domain validation
  #     * check_mx: Boolean (default: true) - Check MX records
  #     * check_a: Boolean (default: false) - Check A records
  #     * timeout: Integer (default: 5) - DNS query timeout in seconds
  #     * validate_format: Boolean (default: true) - Validate email format
  #     * validate_domain: Boolean (default: true) - Validate domain
  #   - normalize: Boolean (default: false) - Normalize email before validation
  #   - message: String or Symbol - Custom error message
  class DomainCheckValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.blank?

      # ActiveModel passes domain_check hash contents directly to options
      # when using validates :email, domain_check: { normalize: false }
      # So options will be { validate_domain: false, normalize: false } etc.
      normalize_option = options[:normalize] == true

      original_value = value.is_a?(String) ? value : value.to_s
      normalized_value = normalize_option ? Normalizer.normalize(original_value) : original_value

      if normalize_option && normalized_value != original_value
        record.public_send("#{attribute}=", normalized_value)
      end

      validation_options = build_validation_options(record, attribute)
      value_for_checker = normalize_option ? normalized_value : original_value
      checker = Checker.new(value_for_checker, validation_options)

      unless checker.valid?
        error_message = error_message_for(record, attribute, checker)
        record.errors.add(attribute, error_message[:key], message: error_message[:message])
      end
    end

    private

    def build_validation_options(record, attribute)
      default_options = {
        validate_format: true,
        validate_domain: true,
        check_mx: true,
        check_a: false,
        timeout: 5
      }

      # ActiveModel passes domain_check hash contents directly to options
      # Exclude normalize and message from validation options
      domain_check_options = options.reject { |k, _v| k == :normalize || k == :message }
      default_options.merge(domain_check_options)
    end

    def error_message_for(record, attribute, checker)
      message_option = options[:message]
      if message_option
        return {
          key: :invalid,
          message: message_option.is_a?(Symbol) ? record.errors.generate_message(attribute, message_option) : message_option
        }
      end

      unless checker.format_valid?
        return {
          key: :invalid_format,
          message: i18n_message("errors.messages.invalid_email_format", "is not a valid email format")
        }
      end

      unless checker.domain_valid?
        return {
          key: :invalid_domain,
          message: i18n_message("errors.messages.invalid_email_domain", "has an invalid domain")
        }
      end

      {
        key: :invalid,
        message: i18n_message("errors.messages.invalid_email", "is not a valid email address")
      }
    end

    def i18n_message(key, default)
      return default unless defined?(I18n)

      I18n.t(key, default: default)
    rescue StandardError
      default
    end
  end
end

DomainCheckValidator = EmailDomainChecker::DomainCheckValidator unless defined?(DomainCheckValidator)
