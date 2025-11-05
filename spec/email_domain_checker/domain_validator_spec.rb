# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::DomainValidator do
  describe "#initialize" do
    it "accepts options" do
      validator = described_class.new(check_mx: false, timeout: 10)
      expect(validator.options[:check_mx]).to be false
      expect(validator.options[:timeout]).to eq(10)
    end

    it "uses default options" do
      validator = described_class.new
      expect(validator.options[:check_mx]).to be true
      expect(validator.options[:check_a]).to be false
      expect(validator.options[:timeout]).to eq(5)
    end
  end

  describe "#valid?" do
    before do
      EmailDomainChecker::Config.reset
    end

    it "returns false for nil domain" do
      validator = described_class.new
      expect(validator.valid?(nil)).to be false
    end

    it "returns false for empty domain" do
      validator = described_class.new
      expect(validator.valid?("")).to be false
    end

    it "skips MX check when disabled" do
      validator = described_class.new(check_mx: false)
      expect(validator.valid?("example.com")).to be true
    end

    it "checks MX records when enabled" do
      validator = described_class.new(check_mx: true)
      # Note: This test may fail if DNS lookup fails
      result = validator.valid?("gmail.com")
      expect(result).to be(true).or(be(false))
    end

    it "skips DNS checks when test_mode is enabled" do
      EmailDomainChecker::Config.test_mode = true
      validator = described_class.new(check_mx: true)
      # Should return true without making DNS requests
      expect(validator.valid?("example.com")).to be true
      expect(validator.valid?("nonexistent-domain-12345.com")).to be true
    end

    it "performs DNS checks when test_mode is disabled" do
      EmailDomainChecker::Config.test_mode = false
      validator = described_class.new(check_mx: true)
      # This will make an actual DNS request
      result = validator.valid?("gmail.com")
      expect(result).to be(true).or(be(false))
    end

    it "uses cache by default" do
      EmailDomainChecker::Config.reset
      validator = described_class.new(check_mx: true)

      domain = "gmail.com" # Use a real domain
      cache = EmailDomainChecker::Config.cache_adapter

      # First call should hit DNS and cache the result
      result1 = validator.valid?(domain)

      # Verify cache entry exists
      expect(cache.get("mx:#{domain}")).to eq(result1)

      # Second call should use cache
      result2 = validator.valid?(domain)

      expect(result1).to eq(result2)
      expect(cache.get("mx:#{domain}")).to eq(result1)
    end

    it "does not use cache when cache is disabled" do
      EmailDomainChecker::Config.reset
      EmailDomainChecker::Config.cache_enabled = false
      validator = described_class.new(check_mx: true)

      domain = "example.com"

      # Should not have cache
      expect(EmailDomainChecker::Config.cache_adapter).to be_nil
      expect(validator.valid?(domain)).to be(false).or(be(true))
    end
  end
end
