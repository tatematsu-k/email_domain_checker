# frozen_string_literal: true

require "active_model"

module EmailDomainChecker
  module Validators
    class NormalizeValidator < ::ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if options[:allow_nil] && value.nil?

        normalized_value = EmailDomainChecker.normalize(value)
        record.public_send("#{attribute}=", normalized_value)
      end
    end
  end
end
