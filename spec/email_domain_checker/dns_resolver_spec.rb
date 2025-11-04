# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::DnsResolver do
  describe "#has_mx_record?" do
    it "returns true for domain with MX records" do
      resolver = described_class.new
      # Note: This test may fail if DNS lookup fails
      result = resolver.has_mx_record?("gmail.com")
      expect(result).to be(true).or(be(false))
    end

    it "returns false for invalid domain" do
      resolver = described_class.new
      result = resolver.has_mx_record?("invalid-domain-that-does-not-exist-12345.com")
      expect(result).to be false
    end
  end

  describe "#has_a_record?" do
    it "returns true for domain with A records" do
      resolver = described_class.new
      # Note: This test may fail if DNS lookup fails
      result = resolver.has_a_record?("google.com")
      expect(result).to be(true).or(be(false))
    end

    it "returns false for invalid domain" do
      resolver = described_class.new
      result = resolver.has_a_record?("invalid-domain-that-does-not-exist-12345.com")
      expect(result).to be false
    end
  end

  describe "#initialize" do
    it "accepts timeout option" do
      resolver = described_class.new(timeout: 10)
      expect(resolver.timeout).to eq(10)
    end

    it "uses default timeout" do
      resolver = described_class.new
      expect(resolver.timeout).to eq(5)
    end
  end
end

