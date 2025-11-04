# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Normalizer do
  describe ".normalize" do
    it "normalizes email address to lowercase" do
      result = described_class.normalize("Test@Example.COM")
      expect(result).to eq("test@example.com")
    end

    it "strips whitespace" do
      result = described_class.normalize("  test@example.com  ")
      expect(result).to eq("test@example.com")
    end

    it "returns empty string for nil input" do
      result = described_class.normalize(nil)
      expect(result).to eq("")
    end

    it "returns empty string for empty input" do
      result = described_class.normalize("")
      expect(result).to eq("")
    end

    it "returns original string if domain is missing" do
      result = described_class.normalize("test")
      expect(result).to eq("test")
    end
  end

  describe ".idn_to_ascii" do
    it "returns domain as-is for ASCII domains" do
      result = described_class.idn_to_ascii("example.com")
      expect(result).to eq("example.com")
    end

    it "handles non-ASCII characters gracefully" do
      result = described_class.idn_to_ascii("例え.テスト")
      expect(result).to be_a(String)
    end
  end
end

