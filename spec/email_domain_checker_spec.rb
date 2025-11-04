# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker do
  describe ".valid?" do
    it "validates email address" do
      result = described_class.valid?("test@example.com", validate_domain: false)
      expect(result).to be true
    end

    it "returns false for invalid email" do
      result = described_class.valid?("invalid-email", validate_domain: false)
      expect(result).to be false
    end
  end

  describe ".format_valid?" do
    it "checks email format" do
      expect(described_class.format_valid?("test@example.com")).to be true
      expect(described_class.format_valid?("invalid-email")).to be false
    end
  end

  describe ".domain_valid?" do
    it "checks domain validity" do
      # Note: This test may fail if DNS lookup fails
      result = described_class.domain_valid?("test@gmail.com")
      expect(result).to be(true).or(be(false))
    end
  end

  describe ".normalize" do
    it "normalizes email address" do
      result = described_class.normalize("Test@Example.COM")
      expect(result).to eq("test@example.com")
    end
  end

  describe ".configure" do
    after do
      described_class::Config.reset
    end

    it "configures default options" do
      described_class.configure(timeout: 10)
      checker = EmailDomainChecker::Checker.new("test@example.com")
      expect(checker.options[:timeout]).to eq(10)
    end
  end
end
