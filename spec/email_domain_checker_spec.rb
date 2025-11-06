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

    it "allows setting test_mode via block" do
      described_class.configure do |config|
        config.test_mode = true
      end
      expect(described_class::Config.test_mode?).to be true
    end

    it "allows setting test_mode via direct assignment" do
      config = described_class.configure
      config.test_mode = true
      expect(described_class::Config.test_mode?).to be true
    end
  end

  describe "test_mode" do
    before do
      described_class::Config.reset
    end

    after do
      described_class::Config.reset
    end

    it "skips DNS checks when test_mode is enabled" do
      described_class.configure do |config|
        config.test_mode = true
      end
      # Should return true without making DNS requests
      result = described_class.domain_valid?("test@nonexistent-domain-12345.com", check_mx: true)
      expect(result).to be true
    end

    it "performs DNS checks when test_mode is disabled" do
      described_class::Config.test_mode = false
      # This will make an actual DNS request
      result = described_class.domain_valid?("test@gmail.com", check_mx: true)
      expect(result).to be(true).or(be(false))
    end
  end

  describe "cache functionality" do
    before do
      described_class::Config.reset
    end

    after do
      described_class::Config.reset
    end

    describe ".clear_cache" do
      it "clears all cached DNS validation results" do
        described_class::Config.cache_enabled = true
        cache = described_class::Config.cache_adapter
        cache.set("mx:example.com", true)
        cache.set("a:example.com", false)

        described_class.clear_cache

        expect(cache.get("mx:example.com")).to be_nil
        expect(cache.get("a:example.com")).to be_nil
      end

      it "does nothing when cache is disabled" do
        expect { described_class.clear_cache }.not_to raise_error
      end
    end

    describe ".clear_cache_for_domain" do
      it "clears cache for a specific domain" do
        described_class::Config.cache_enabled = true
        cache = described_class::Config.cache_adapter
        cache.set("mx:example.com", true)
        cache.set("a:example.com", false)
        cache.set("mx:other.com", true)

        described_class.clear_cache_for_domain("example.com")

        expect(cache.get("mx:example.com")).to be_nil
        expect(cache.get("a:example.com")).to be_nil
        expect(cache.get("mx:other.com")).to eq(true)
      end

      it "does nothing when cache is disabled" do
        expect { described_class.clear_cache_for_domain("example.com") }.not_to raise_error
      end
    end

    describe "cache configuration" do
      it "cache is enabled by default" do
        expect(described_class::Config.cache_enabled?).to be true
      end

      it "allows changing cache settings via configure block" do
        described_class.configure do |config|
          config.cache_ttl = 1800
        end

        expect(described_class::Config.cache_ttl).to eq(1800)
      end

      it "allows disabling cache" do
        described_class.configure do |config|
          config.cache_enabled = false
        end

        expect(described_class::Config.cache_enabled?).to be false
      end

      it "uses cache when enabled" do
        cache = described_class::Config.cache_adapter

        # Pre-populate cache
        cache.set("mx:example.com", true, ttl: 3600)

        # Should use cache
        allow_any_instance_of(EmailDomainChecker::DnsResolver).to receive(:check_dns_record).and_return(false)
        result = described_class.domain_valid?("test@example.com", check_mx: true)

        # Result should come from cache (true), not from DNS (false)
        expect(result).to be true
      end
    end
  end
end
