# frozen_string_literal: true

module RSpec
  class ExpectationNotMetError < StandardError; end

  class Configuration
    attr_accessor :example_status_persistence_file_path

    def disable_monkey_patching!; end

    def expect_with(_framework)
      yield ExpectationConfiguration.new
    end

    class ExpectationConfiguration
      attr_accessor :syntax
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def registry
      @registry ||= []
    end

    def reset_registry
      @registry = []
    end

    def describe(description, &block)
      group = ExampleGroup.new(description)
      group.instance_eval(&block) if block
      registry << group
      group
    end

    def run
      reporter = Reporter.new
      registry.each { |group| group.run(reporter) }
      reporter.finish
      reporter.success?
    ensure
      reset_registry
    end

    def expect(value)
      Expectations::ExpectationTarget.new(value)
    end

    def allow(object)
      Mocks::AllowanceBuilder.new(object)
    end

    def receive(method_name)
      Mocks::ReceiveMatcher.new(method_name)
    end
  end

  module Matchers
    class Base
      def or(other)
        OrMatcher.new(self, other)
      end
    end

    class BeMatcher < Base
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        actual == @expected
      end

      def failure_message(actual)
        "expected #{actual.inspect} to be #{@expected.inspect}"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} not to be #{@expected.inspect}"
      end
    end

    class EqMatcher < Base
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        actual == @expected
      end

      def failure_message(actual)
        "expected #{actual.inspect} to equal #{@expected.inspect}"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} not to equal #{@expected.inspect}"
      end
    end

    class IncludeMatcher < Base
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        actual.respond_to?(:include?) && actual.include?(@expected)
      end

      def failure_message(actual)
        "expected #{actual.inspect} to include #{@expected.inspect}"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} not to include #{@expected.inspect}"
      end
    end

    class BeAKindOfMatcher < Base
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        actual.is_a?(@expected)
      end

      def failure_message(actual)
        "expected #{actual.inspect} to be a #{@expected}"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} not to be a #{@expected}"
      end
    end

    class BeNilMatcher < Base
      def matches?(actual)
        actual.nil?
      end

      def failure_message(actual)
        "expected #{actual.inspect} to be nil"
      end

      def failure_message_when_negated(_actual)
        "expected value not to be nil"
      end
    end

    class MatchMatcher < Base
      def initialize(pattern)
        @pattern = pattern
      end

      def matches?(actual)
        actual =~ @pattern
      end

      def failure_message(actual)
        "expected #{actual.inspect} to match #{@pattern.inspect}"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} not to match #{@pattern.inspect}"
      end
    end

    class OrMatcher < Base
      def initialize(left, right)
        @left = left
        @right = right
      end

      def matches?(actual)
        @left.matches?(actual) || @right.matches?(actual)
      end

      def failure_message(actual)
        "expected #{actual.inspect} to satisfy either matcher"
      end

      def failure_message_when_negated(actual)
        "expected #{actual.inspect} to satisfy neither matcher"
      end
    end

    def be(value)
      BeMatcher.new(value)
    end

    def eq(value)
      EqMatcher.new(value)
    end

    def include(value)
      IncludeMatcher.new(value)
    end

    def be_a(value)
      BeAKindOfMatcher.new(value)
    end
    alias be_an be_a

    def be_nil
      BeNilMatcher.new
    end

    def match(pattern)
      MatchMatcher.new(pattern)
    end
  end

  module Expectations
    class ExpectationTarget
      def initialize(actual)
        @actual = actual
      end

      def to(matcher)
        if matcher.respond_to?(:setup_expectation)
          matcher.setup_expectation(@actual, :expect)
        elsif matcher.respond_to?(:matches?)
          raise ExpectationNotMetError, matcher.failure_message(@actual) unless matcher.matches?(@actual)
        else
          raise ArgumentError, "Invalid matcher provided"
        end
      end

      def not_to(matcher)
        if matcher.respond_to?(:setup_expectation)
          matcher.setup_expectation(@actual, :disallow)
        elsif matcher.respond_to?(:matches?)
          raise ExpectationNotMetError, matcher.failure_message_when_negated(@actual) if matcher.matches?(@actual)
        else
          raise ArgumentError, "Invalid matcher provided"
        end
      end
      alias to_not not_to
    end
  end

  module Mocks
    class << self
      def registry
        @registry ||= []
      end

      def register(expectation)
        registry << expectation
      end

      def verify!
        registry.each(&:verify!)
      end

      def reset!
        registry.each(&:teardown)
        @registry = []
      end
    end

    class ReceiveMatcher
      def initialize(method_name)
        @method_name = method_name
        @expected_args = nil
        @return_value = nil
      end

      def with(*args)
        @expected_args = args
        self
      end

      def and_return(value)
        @return_value = value
        self
      end

      def setup_expectation(object, mode)
        expectation = MethodExpectation.new(object, @method_name, @expected_args, @return_value, mode)
        expectation.install
        Mocks.register(expectation)
        expectation
      end
    end

    class MethodExpectation
      def initialize(object, method_name, expected_args, return_value, mode)
        @object = object
        @method_name = method_name
        @expected_args = expected_args
        @return_value = return_value
        @mode = mode
        @calls = 0
        @original_defined = object.singleton_methods.include?(method_name)
        @original_method = object.method(method_name) if @original_defined
      end

      def install
        expectation = self
        @object.define_singleton_method(@method_name) do |*args, &block|
          expectation.record_call(args, &block)
        end
      end

      def record_call(args)
        if @expected_args && args != @expected_args
          raise ExpectationNotMetError, "expected #{@object}.#{@method_name} to be called with #{@expected_args.inspect}, but received #{args.inspect}"
        end

        if @mode == :disallow
          raise ExpectationNotMetError, "expected #{@object}.#{@method_name} not to be called"
        end

        @calls += 1
        @return_value
      end

      def verify!
        case @mode
        when :expect
          raise ExpectationNotMetError, "expected #{@object}.#{@method_name} to be called" if @calls.zero?
        when :disallow
          raise ExpectationNotMetError, "expected #{@object}.#{@method_name} not to be called" if @calls.positive?
        end
      end

      def teardown
        if @original_defined
          original = @original_method
          @object.define_singleton_method(@method_name) do |*args, &block|
            original.call(*args, &block)
          end
        else
          @object.singleton_class.send(:remove_method, @method_name)
        end
      rescue NameError
        # Method already removed
      end
    end

    class AllowanceBuilder
      def initialize(object)
        @object = object
      end

      def to(matcher)
        matcher.setup_expectation(@object, :allow)
      end
    end
  end

  class ExampleGroup
    attr_reader :description, :parent

    def initialize(description, parent = nil)
      @description = description
      @parent = parent
      @examples = []
      @children = []
      @let_definitions = {}
      @after_hooks = []
    end

    def describe(desc, &block)
      child = ExampleGroup.new(desc, self)
      child.instance_eval(&block) if block
      @children << child
      child
    end

    def let(name, &block)
      @let_definitions[name] = block
    end

    def after(&block)
      @after_hooks << block
    end

    def it(description, &block)
      @examples << Example.new(description, block, self)
    end

    def run(reporter)
      @examples.each { |example| example.run(reporter) }
      @children.each { |child| child.run(reporter) }
    end

    def let_definitions
      if parent
        parent.let_definitions.merge(@let_definitions)
      else
        @let_definitions.dup
      end
    end

    def after_hooks
      hooks = parent ? parent.after_hooks : []
      hooks + @after_hooks
    end

    def described_class
      if description.is_a?(Module) || description.is_a?(Class)
        description
      elsif parent
        parent.described_class
      else
        nil
      end
    end
  end

  class Example
    def initialize(description, block, group)
      @description = description
      @block = block
      @group = group
    end

    def run(reporter)
      instance = ExampleInstance.new(@group)
      error = nil

      begin
        instance.instance_exec(&@block)
      rescue Exception => example_error
        error = example_error
      end

      @group.after_hooks.each do |hook|
        begin
          instance.instance_exec(&hook)
        rescue Exception => hook_error
          error ||= hook_error
        end
      end

      begin
        Mocks.verify!
      rescue Exception => mock_error
        error ||= mock_error
      end

      if error
        reporter.example_failed(@description, error)
      else
        reporter.example_passed(@description)
      end
    ensure
      Mocks.reset!
    end
  end

  class ExampleInstance
    include Matchers

    def initialize(group)
      @group = group
      define_let_methods
    end

    def expect(value)
      Expectations::ExpectationTarget.new(value)
    end

    def allow(object)
      Mocks::AllowanceBuilder.new(object)
    end

    def described_class
      @group.described_class
    end

    def receive(method_name)
      RSpec.receive(method_name)
    end

    def method_missing(method_name, *args, &block)
      if respond_to_missing?(method_name)
        send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @group.let_definitions.key?(method_name) || super
    end

    private

    def define_let_methods
      @memoized = {}
      @group.let_definitions.each do |name, block|
        define_singleton_method(name) do
          if @memoized.key?(name)
            @memoized[name]
          else
            @memoized[name] = instance_exec(&block)
          end
        end
      end
    end
  end

  class Reporter
    def initialize
      @examples = []
    end

    def example_passed(description)
      @examples << { description: description, status: :passed }
      print '.'
    end

    def example_failed(description, error)
      @examples << { description: description, status: :failed, error: error }
      print 'F'
    end

    def finish
      puts
      failed = @examples.select { |ex| ex[:status] == :failed }
      failed.each_with_index do |ex, index|
        puts
        puts "  #{index + 1}) #{ex[:description]}"
        puts "     Failure/Error: #{ex[:error].message}"
      end
      puts
      puts "Finished in 0 seconds"
      puts "#{@examples.count} examples, #{failed.count} failures"
    end

    def success?
      @examples.none? { |ex| ex[:status] == :failed }
    end
  end
end

module Kernel
  def describe(description, &block)
    RSpec.describe(description, &block)
  end
end
