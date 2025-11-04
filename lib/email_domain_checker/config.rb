# frozen_string_literal: true

module EmailDomainChecker
  class Config
    DEFAULT_OPTIONS = {
      validate_format: true,
      validate_domain: true,
      check_mx: true,
      check_a: false,
      timeout: 5
    }.freeze

    class << self
      attr_accessor :default_options

      def configure(options = {})
        @default_options = DEFAULT_OPTIONS.merge(options)
      end

      def reset
        @default_options = DEFAULT_OPTIONS.dup
      end
    end

    reset
  end
end
