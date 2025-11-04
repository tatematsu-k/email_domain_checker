# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::EmailAddressAdapter do
  describe "#initialize" do
    it "creates adapter with email address" do
      adapter = described_class.new("test@example.com")
      expect(adapter.email_address).to be_a(EmailAddress::Address)
    end
  end

  describe "#valid?" do
    it "returns true for valid email" do
      adapter = described_class.new("test@example.com")
      expect(adapter.valid?).to be true
    end

    it "returns false for invalid email" do
      adapter = described_class.new("invalid-email")
      expect(adapter.valid?).to be false
    end
  end

  describe "#normalized" do
    it "returns normalized email address" do
      adapter = described_class.new("Test@Example.COM")
      normalized = adapter.normalized
      expect(normalized).to be_a(String)
      expect(normalized).to match(/test@example\.com/i)
    end
  end

  describe "#canonical" do
    it "returns canonical email address" do
      adapter = described_class.new("user.name+tag@gmail.com")
      canonical = adapter.canonical
      expect(canonical).to be_a(String)
      expect(canonical).to match(/@gmail\.com/)
    end
  end

  describe "#redacted" do
    it "returns redacted email address" do
      adapter = described_class.new("test@example.com")
      redacted = adapter.redacted
      expect(redacted).to be_a(String)
      expect(redacted).to match(/@example\.com/)
    end
  end
end

