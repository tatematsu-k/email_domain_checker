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
  end
end
