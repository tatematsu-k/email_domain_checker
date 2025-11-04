# frozen_string_literal: true

module ActiveModel
  module Validations
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validators
        @_validators ||= []
      end

      def validates(*attributes, **options)
        if options.empty?
          last = attributes.pop
          unless last.is_a?(Hash)
            raise ArgumentError, "You need to supply at least one validator"
          end
          options = last
        end

        options.each do |validator_name, validator_options|
          validator_options = {} if validator_options == true
          validator_class = lookup_validator_class(validator_name)
          validators << validator_class.new(attributes: attributes, **validator_options)
        end
      end

      private

      def lookup_validator_class(name)
        const_name = camelize(name) + "Validator"
        if ActiveModel::Validations.const_defined?(const_name, false)
          ActiveModel::Validations.const_get(const_name)
        else
          raise ArgumentError, "Unknown validator: '#{const_name}'"
        end
      end

      def camelize(name)
        name.to_s.split('_').map(&:capitalize).join
      end
    end

    def errors
      @errors ||= Errors.new
    end

    def valid?
      errors.clear
      self.class.validators.each do |validator|
        validator.validate(self)
      end
      errors.empty?
    end
  end

  class Errors
    def initialize
      @messages = Hash.new { |h, k| h[k] = [] }
    end

    def add(attribute, message)
      @messages[attribute] << message
    end

    def [](attribute)
      @messages[attribute]
    end

    def clear
      @messages.clear
    end

    def empty?
      @messages.all? { |_attr, messages| messages.empty? }
    end
  end

  module Validations
    class EachValidator
      attr_reader :attributes, :options

      def initialize(options = {})
        attributes = options.delete(:attributes) || []
        @attributes = Array(attributes)
        @options = options
      end

      def validate(record)
        attributes.each do |attribute|
          value = record.public_send(attribute)
          validate_each(record, attribute, value)
        end
      end

      def validate_each(_record, _attribute, _value)
        raise NotImplementedError
      end
    end
  end

  EachValidator = Validations::EachValidator

  module Model
    def self.included(base)
      base.include(ActiveModel::Validations)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods
      def initialize(attributes = {})
        assign_attributes(attributes) if attributes
      end

      def assign_attributes(attributes)
        attributes.each do |attr, value|
          writer = "#{attr}="
          public_send(writer, value) if respond_to?(writer)
        end
      end
    end

    module ClassMethods
    end
  end
end
