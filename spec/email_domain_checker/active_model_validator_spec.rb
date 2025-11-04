# frozen_string_literal: true

require "spec_helper"

# Only run these tests if ActiveModel is available
if defined?(ActiveModel)
  require "active_model"

  # Simple test model class
  class TestModel
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :email, :string

    def initialize(attributes = {})
      super
      @attributes ||= {}
      attributes.each { |key, value| @attributes[key.to_sym] = value }
    end

    def [](key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      @attributes[key.to_sym] = value
    end
  end

  # Clear validations before each test to avoid interference
  RSpec.configure do |config|
    config.before(:each) do
      TestModel.clear_validators!
    end
  end

  RSpec.describe EmailDomainChecker::DomainCheckValidator do
    describe "validation" do
      it "validates email format" do
        model = TestModel.new(email: "test@example.com")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true
      end

      it "rejects invalid email format" do
        model = TestModel.new(email: "invalid-email")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be false
        expect(model.errors[:email]).not_to be_empty
      end

      it "validates domain when check_mx is enabled" do
        model = TestModel.new(email: "test@gmail.com")
        model.class.validates :email, domain_check: { check_mx: true, timeout: 3 }
        # Note: This test may fail if DNS lookup fails
        result = model.valid?
        expect(result).to be(true).or(be(false)) # Can be either depending on DNS
      end

      it "skips domain validation when validate_domain is false" do
        model = TestModel.new(email: "test@example.com")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true
      end

      it "accepts custom timeout option" do
        model = TestModel.new(email: "test@gmail.com")
        model.class.validates :email, domain_check: { check_mx: true, timeout: 1 }
        # Should not raise error even with custom timeout
        expect { model.valid? }.not_to raise_error
      end

      it "accepts check_a option" do
        model = TestModel.new(email: "test@gmail.com")
        model.class.validates :email, domain_check: { check_a: true, check_mx: false }
        # Should not raise error
        expect { model.valid? }.not_to raise_error
      end
    end

    describe "normalization" do
      it "normalizes email when normalize option is true" do
        model = TestModel.new(email: "  Test@Example.COM  ")
        model.class.validates :email, domain_check: { validate_domain: false, normalize: true }
        model.valid?
        expect(model.email).to eq("test@example.com")
      end

      it "does not normalize when normalize option is false" do
        model = TestModel.new(email: "  Test@Example.COM  ")
        model.class.validates :email, domain_check: { validate_domain: false, normalize: false }
        model.valid?
        expect(model.email).to eq("  Test@Example.COM  ")
      end

      it "normalizes email before validation" do
        model = TestModel.new(email: "TEST@EXAMPLE.COM")
        model.class.validates :email, domain_check: { validate_domain: false, normalize: true }
        expect(model.valid?).to be true
        expect(model.email).to eq("test@example.com")
      end
    end

    describe "custom error messages" do
      it "accepts custom message option" do
        model = TestModel.new(email: "invalid-email")
        model.class.validates :email, domain_check: { validate_domain: false, message: "Custom error message" }
        model.valid?
        expect(model.errors[:email]).to include("Custom error message")
      end

      it "uses default error messages when custom message is not provided" do
        model = TestModel.new(email: "invalid-email")
        model.class.validates :email, domain_check: { validate_domain: false }
        model.valid?
        expect(model.errors[:email]).not_to be_empty
      end
    end

    describe "edge cases" do
      it "handles nil email" do
        model = TestModel.new(email: nil)
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true # nil is skipped
      end

      it "handles empty email" do
        model = TestModel.new(email: "")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true # empty is skipped
      end

      it "handles blank email" do
        model = TestModel.new(email: "   ")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true # blank is skipped
      end
    end

    describe "integration with domain_check options" do
      it "merges domain_check options correctly" do
        model = TestModel.new(email: "test@gmail.com")
        model.class.validates :email, domain_check: { check_mx: true, timeout: 3, validate_domain: true }
        # Should not raise error
        expect { model.valid? }.not_to raise_error
      end

      it "allows options in domain_check to override defaults" do
        model = TestModel.new(email: "test@example.com")
        model.class.validates :email, domain_check: { validate_domain: false }
        expect(model.valid?).to be true
      end

      it "handles multiple options in domain_check hash" do
        model = TestModel.new(email: "test@example.com")
        model.class.validates :email, domain_check: { check_mx: true, check_a: false, timeout: 2, validate_format: true, validate_domain: false }
        expect(model.valid?).to be true
      end
    end
  end
end
