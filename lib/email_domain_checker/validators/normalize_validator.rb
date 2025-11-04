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
      class NormalizeValidator < ::ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          return if value.nil? && options[:allow_nil]
          return if options[:allow_blank] && blank?(value)

          normalized_value = EmailDomainChecker.normalize(value)
          record.public_send("#{attribute}=", normalized_value)
        end

        private

        def blank?(value)
          value.nil? || value.respond_to?(:empty?) && value.empty? ||
            value.respond_to?(:strip) && value.strip.empty?
        end
      end
    end
  end
end
