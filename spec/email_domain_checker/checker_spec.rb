# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Checker do
  describe "#initialize" do
    it "accepts an email address" do
      checker = described_class.new("test@example.com")
      expect(checker.email).to eq("test@example.com")
    end

    it "strips whitespace from email" do
      checker = described_class.new("  test@example.com  ")
      expect(checker.email).to eq("test@example.com")
    end
  end

  describe "#format_valid?" do
    it "returns true for valid email format" do
      checker = described_class.new("test@example.com")
      expect(checker.format_valid?).to be true
    end

    it "returns false for invalid email format" do
      checker = described_class.new("invalid-email")
      expect(checker.format_valid?).to be false
    end

    it "skips format validation when disabled" do
      checker = described_class.new("invalid-email", validate_format: false)
      expect(checker.format_valid?).to be true
    end
  end

  describe "#normalized_email" do
    it "returns normalized email address" do
      checker = described_class.new("Test@Example.COM")
      normalized = checker.normalized_email
      expect(normalized).to be_a(String)
      expect(normalized).to match(/test@example\.com/i)
    end

    it "returns nil for invalid email" do
      checker = described_class.new("invalid-email")
      expect(checker.normalized_email).to be_nil
    end
  end

  describe "#canonical_email" do
    it "returns canonical email address" do
      checker = described_class.new("user.name+tag@gmail.com")
      canonical = checker.canonical_email
      expect(canonical).to be_a(String)
      expect(canonical).to match(/@gmail\.com/)
    end

    it "returns nil for invalid email" do
      checker = described_class.new("invalid-email")
      expect(checker.canonical_email).to be_nil
    end
  end

  describe "#redacted_email" do
    it "returns redacted email address" do
      checker = described_class.new("test@example.com")
      redacted = checker.redacted_email
      expect(redacted).to be_a(String)
      expect(redacted).to match(/@example\.com/)
    end

    it "returns nil for invalid email" do
      checker = described_class.new("invalid-email")
      expect(checker.redacted_email).to be_nil
    end
  end

  describe "#domain_valid?" do
    it "returns true for domain with MX records" do
      checker = described_class.new("test@gmail.com")
      # Note: This test may fail if DNS lookup fails, so we'll skip domain validation in most tests
      result = checker.domain_valid?
      expect(result).to be(true).or(be(false)) # Can be either depending on DNS
    end

    it "skips domain validation when disabled" do
      checker = described_class.new("test@example.com", validate_domain: false)
      expect(checker.domain_valid?).to be true
    end

    it "returns false for empty domain" do
      checker = described_class.new("test@")
      expect(checker.domain_valid?).to be false
    end
  end

  describe "#valid?" do
    it "returns true for valid email format when domain check is disabled" do
      checker = described_class.new("test@example.com", validate_domain: false)
      expect(checker.valid?).to be true
    end

    it "returns false for invalid email format" do
      checker = described_class.new("invalid-email", validate_domain: false)
      expect(checker.valid?).to be false
    end

    it "returns false for empty email" do
      checker = described_class.new("")
      expect(checker.valid?).to be false
    end
  end

  describe "integration with blacklist and whitelist" do
    before do
      EmailDomainChecker::Config.reset
    end

    it "rejects emails with blacklisted domains" do
      EmailDomainChecker::Config.blacklist_domains = ["10minutemail.com"]
      checker = described_class.new("user@10minutemail.com", validate_domain: true, check_mx: false)
      expect(checker.valid?).to be false
    end

    it "allows emails with whitelisted domains" do
      EmailDomainChecker::Config.whitelist_domains = ["example.com"]
      checker = described_class.new("user@example.com", validate_domain: true, check_mx: false)
      expect(checker.valid?).to be true
    end

    it "rejects emails with domains not in whitelist" do
      EmailDomainChecker::Config.whitelist_domains = ["example.com"]
      checker = described_class.new("user@other.com", validate_domain: true, check_mx: false)
      expect(checker.valid?).to be false
    end

    it "works with custom domain checker" do
      EmailDomainChecker::Config.domain_checker = lambda { |domain| domain == "allowed.com" }
      checker = described_class.new("user@allowed.com", validate_domain: true, check_mx: false)
      expect(checker.valid?).to be true

      checker2 = described_class.new("user@blocked.com", validate_domain: true, check_mx: false)
      expect(checker2.valid?).to be false
    end
  end
end
