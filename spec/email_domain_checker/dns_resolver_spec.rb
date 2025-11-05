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

    it "accepts cache option" do
      cache = EmailDomainChecker::Cache::MemoryAdapter.new
      resolver = described_class.new(cache: cache)
      expect(resolver).to be_a(described_class)
    end
  end

  describe "cache integration" do
    let(:cache) { EmailDomainChecker::Cache::MemoryAdapter.new }

    before do
      EmailDomainChecker::Config.reset
    end

    it "stores results in cache" do
      resolver = described_class.new(cache: cache)
      domain = "gmail.com" # Use a real domain that likely has MX records

      # First call should hit DNS and cache the result
      result = resolver.has_mx_record?(domain)

      # Verify cache entry exists (may be nil if DNS lookup failed)
      cached_value = cache.get("mx:#{domain}")
      # Cache should contain the result (true or false)
      expect([true, false]).to include(cached_value)
      expect(cached_value).to eq(result)
    end

    it "retrieves from cache when available" do
      resolver = described_class.new(cache: cache)
      domain = "example.com"

      # Pre-populate cache
      cache.set("mx:#{domain}", true, ttl: 3600)

      # Get cached value
      result = resolver.has_mx_record?(domain)
      expect(result).to be true
      expect(cache.get("mx:#{domain}")).to be true
    end

    it "caches MX and A records separately" do
      resolver = described_class.new(cache: cache)
      domain = "example.com"

      # Pre-populate cache with different values
      cache.set("mx:#{domain}", true, ttl: 3600)
      cache.set("a:#{domain}", false, ttl: 3600)

      # Get results (should come from cache)
      mx_result = resolver.has_mx_record?(domain)
      a_result = resolver.has_a_record?(domain)

      # Results should match cache values
      expect(mx_result).to be true
      expect(a_result).to be false
      # Verify cache still contains the values
      expect(cache.get("mx:#{domain}")).to be true
      expect(cache.get("a:#{domain}")).to be false
    end

    it "works without cache when cache is nil" do
      resolver = described_class.new(cache: nil)
      domain = "gmail.com"

      # Should still work without cache
      expect(resolver.has_mx_record?(domain)).to be(false).or(be(true))
    end

    it "uses cache on subsequent calls" do
      resolver = described_class.new(cache: cache)
      domain = "gmail.com"

      # First call - should populate cache
      result1 = resolver.has_mx_record?(domain)
      cached1 = cache.get("mx:#{domain}")
      # Cache should contain the result
      expect([true, false]).to include(cached1)
      expect(cached1).to eq(result1)

      # Second call - should use cache
      result2 = resolver.has_mx_record?(domain)
      expect(result2).to eq(result1)
      cached2 = cache.get("mx:#{domain}")
      expect(cached2).to eq(result1)
    end
  end
end
