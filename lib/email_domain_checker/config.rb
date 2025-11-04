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
      attr_accessor :default_options, :test_mode

      def configure(options = {}, &block)
        if block_given?
          config_instance = new
          block.call(config_instance)
          @default_options = DEFAULT_OPTIONS.merge(options)
          config_instance
        else
          @default_options = DEFAULT_OPTIONS.merge(options)
          new
        end
      end

      def reset
        @default_options = DEFAULT_OPTIONS.dup
        @test_mode = false
      end

      def test_mode=(value)
        @test_mode = value
      end

      def test_mode?
        @test_mode == true
      end
    end

    attr_accessor :test_mode

    def initialize
      @test_mode = self.class.test_mode || false
    end

    def test_mode=(value)
      @test_mode = value
      self.class.test_mode = value
    end

    reset
  end
end
