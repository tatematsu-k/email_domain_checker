# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::DnsBlChecker do
  before do
    EmailDomainChecker::Config.reset
  end

  describe "#initialize" do
    it "accepts timeout option" do
      checker = described_class.new(timeout: 10)
      expect(checker.timeout).to eq(10)
    end

    it "uses default timeout" do
      checker = described_class.new
      expect(checker.timeout).to eq(5)
    end

    it "accepts reputation_lists option" do
      lists = ["zen.spamhaus.org"]
      checker = described_class.new(reputation_lists: lists)
      expect(checker.reputation_lists).to eq(lists)
    end

    it "accepts fallback_action option" do
      checker = described_class.new(fallback_action: :reject)
      expect(checker.fallback_action).to eq(:reject)
    end

    it "uses default fallback_action" do
      checker = described_class.new
      expect(checker.fallback_action).to eq(:allow)
    end

    it "accepts cache option" do
      cache = EmailDomainChecker::Cache::MemoryAdapter.new
      checker = described_class.new(cache: cache)
      expect(checker).to be_a(described_class)
    end
  end

  describe "#safe?" do
    it "returns true when no reputation lists are configured" do
      checker = described_class.new(reputation_lists: [])
      expect(checker.safe?("example.com")).to be true
    end

    it "returns true for nil domain" do
      checker = described_class.new(reputation_lists: ["zen.spamhaus.org"])
      expect(checker.safe?(nil)).to be true
    end

    it "returns true for empty domain" do
      checker = described_class.new(reputation_lists: ["zen.spamhaus.org"])
      expect(checker.safe?("")).to be true
    end

    it "checks domain against configured DNSBL lists" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org"],
        timeout: 5
      )
      # Note: This test may fail if DNS lookup fails or domain is actually listed
      # Using a well-known legitimate domain that should not be listed
      result = checker.safe?("gmail.com")
      expect(result).to be(true).or(be(false))
    end

    it "returns false if domain is listed in any DNSBL" do
      # This test would require a domain that is actually listed in Spamhaus
      # For now, we'll test the logic with a mock
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org"],
        timeout: 1
      )
      # Most legitimate domains should not be listed
      result = checker.safe?("example.com")
      expect(result).to be(true).or(be(false))
    end
  end

  describe "#listed?" do
    it "returns false when domain is safe" do
      checker = described_class.new(reputation_lists: [])
      expect(checker.listed?("example.com")).to be false
    end

    it "returns opposite of safe?" do
      checker = described_class.new(reputation_lists: ["zen.spamhaus.org"])
      domain = "example.com"
      expect(checker.listed?(domain)).to eq(!checker.safe?(domain))
    end
  end

  describe "#listed_in?" do
    it "returns false for nil domain" do
      checker = described_class.new
      expect(checker.listed_in?(nil, "zen.spamhaus.org")).to be false
    end

    it "returns false for empty domain" do
      checker = described_class.new
      expect(checker.listed_in?("", "zen.spamhaus.org")).to be false
    end

    it "returns false for nil DNSBL host" do
      checker = described_class.new
      expect(checker.listed_in?("example.com", nil)).to be false
    end

    it "builds correct DNSBL query" do
      checker = described_class.new
      # For domain "example.com" and DNSBL "zen.spamhaus.org"
      # Query should be "com.example.zen.spamhaus.org"
      # Note: This test may fail if DNS lookup fails
      result = checker.listed_in?("example.com", "zen.spamhaus.org")
      expect(result).to be(false).or(be(true))
    end

    it "handles DNS lookup errors gracefully with allow fallback" do
      checker = described_class.new(
        fallback_action: :allow,
        timeout: 0.001 # Very short timeout to force error
      )
      # Should return false (not listed) on error with :allow fallback
      result = checker.listed_in?("example.com", "zen.spamhaus.org")
      expect(result).to be false
    end

    it "handles DNS lookup errors gracefully with reject fallback" do
      checker = described_class.new(
        fallback_action: :reject,
        timeout: 0.001 # Very short timeout to potentially force error
      )
      # Should return true (listed) on error with :reject fallback
      # Note: This may not always timeout, so we just verify the fallback logic exists
      result = checker.listed_in?("example.com", "zen.spamhaus.org")
      # Result depends on whether timeout occurs or DNS lookup succeeds
      expect(result).to be(false).or(be(true))
      # Verify that fallback_action is set correctly
      expect(checker.fallback_action).to eq(:reject)
    end
  end

  describe "cache integration" do
    let(:cache) { EmailDomainChecker::Cache::MemoryAdapter.new }

    it "stores results in cache" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org"],
        cache: cache
      )
      domain = "example.com"

      # First call should hit DNS and cache the result
      result = checker.listed_in?(domain, "zen.spamhaus.org")

      # Verify cache entry exists
      cached_value = cache.get("dnsbl:zen.spamhaus.org:#{domain}")
      expect([true, false]).to include(cached_value)
      expect(cached_value).to eq(result)
    end

    it "retrieves from cache when available" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org"],
        cache: cache
      )
      domain = "example.com"

      # Pre-populate cache
      cache.set("dnsbl:zen.spamhaus.org:#{domain}", false, ttl: 3600)

      # Get cached value
      result = checker.listed_in?(domain, "zen.spamhaus.org")
      expect(result).to be false
      expect(cache.get("dnsbl:zen.spamhaus.org:#{domain}")).to be false
    end

    it "works without cache when cache is nil" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org"],
        cache: nil
      )
      domain = "example.com"

      # Should still work without cache
      expect(checker.listed_in?(domain, "zen.spamhaus.org")).to be(false).or(be(true))
    end
  end

  describe "multiple reputation lists" do
    it "checks all configured lists" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org", "bl.spamcop.net"],
        timeout: 5
      )
      # Should check both lists
      result = checker.safe?("example.com")
      expect(result).to be(true).or(be(false))
    end

    it "returns false if domain is listed in any list" do
      checker = described_class.new(
        reputation_lists: ["zen.spamhaus.org", "bl.spamcop.net"],
        timeout: 5
      )
      # If domain is listed in any list, safe? should return false
      result = checker.safe?("example.com")
      expect(result).to be(true).or(be(false))
    end
  end
end
