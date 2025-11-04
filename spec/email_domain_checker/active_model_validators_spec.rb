# frozen_string_literal: true

require "spec_helper"
require "active_model"

RSpec.describe "ActiveModel validators" do
  let(:valid_email) { "user@example.com" }

  describe EmailDomainChecker::Validators::NormalizeValidator do
    let(:model_class) do
      Class.new do
        include ::ActiveModel::Model

        attr_accessor :email

        validates :email, normalize: true
      end
    end

    it "normalizes the email attribute before validation" do
      instance = model_class.new(email: "User@Example.COM")

      expect(instance.valid?).to be(true)
      expect(instance.email).to eq("user@example.com")
    end
  end

  describe EmailDomainChecker::Validators::DomainCheckValidator do
    let(:model_class) do
      Class.new do
        include ::ActiveModel::Model

        attr_accessor :email

        validates :email, domain_check: true
      end
    end

    it "delegates validation to EmailDomainChecker" do
      instance = model_class.new(email: valid_email)

      expect(EmailDomainChecker).to receive(:valid?).with(valid_email, {}).and_return(true)
      expect(instance.valid?).to be(true)
    end

    it "adds an error when the email domain is invalid" do
      instance = model_class.new(email: valid_email)

      allow(EmailDomainChecker).to receive(:valid?).and_return(false)

      expect(instance.valid?).to be(false)
      expect(instance.errors[:email]).to include("has an invalid email domain")
    end

    it "forwards validation options to the checker" do
      custom_model_class = Class.new do
        include ::ActiveModel::Model

        attr_accessor :email

        validates :email, domain_check: { check_mx: false, timeout: 1 }
      end

      instance = custom_model_class.new(email: valid_email)

      expect(EmailDomainChecker).to receive(:valid?).with(valid_email, check_mx: false, timeout: 1).and_return(true)
      expect(instance.valid?).to be(true)
    end

    it "respects allow_blank option" do
      allow_blank_model = Class.new do
        include ::ActiveModel::Model

        attr_accessor :email

        validates :email, domain_check: { allow_blank: true }
      end

      instance = allow_blank_model.new(email: "")

      expect(EmailDomainChecker).not_to receive(:valid?)
      expect(instance.valid?).to be(true)
    end
  end
end
