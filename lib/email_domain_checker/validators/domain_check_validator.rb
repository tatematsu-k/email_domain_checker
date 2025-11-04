# frozen_string_literal: true

begin
  require "active_model"
rescue LoadError
  # ActiveModel is optional – skip defining the validator when it's not available.
end

module EmailDomainChecker
  module Validators
  end
end

if defined?(::ActiveModel::EachValidator)
  module EmailDomainChecker
    module Validators
      class DomainCheckValidator < ::ActiveModel::EachValidator
        DEFAULT_MESSAGE = "has an invalid email domain".freeze
        CHECKER_OPTION_KEYS = %i[validate_format validate_domain check_mx check_a timeout].freeze

        def validate_each(record, attribute, value)
          return if skip_validation?(value)

          normalized_value = EmailDomainChecker.normalize(value)
          return if EmailDomainChecker.valid?(normalized_value, checker_options)

          record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
        end

        private

        def skip_validation?(value)
          (options[:allow_nil] && value.nil?) ||
            (options[:allow_blank] && blank?(value))
        end

        def blank?(value)
          value.nil? || value.respond_to?(:empty?) && value.empty? ||
            value.respond_to?(:strip) && value.strip.empty?
        end

        def checker_options
          CHECKER_OPTION_KEYS.each_with_object({}) do |key, hash|
            hash[key] = options[key] if options.key?(key)
          end
        end
      end
    end
  end

  unless ::ActiveModel::Validations.const_defined?(:DomainCheckValidator)
    ::ActiveModel::Validations.const_set(:DomainCheckValidator, EmailDomainChecker::Validators::DomainCheckValidator)
  end
end
