# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Config do
  describe ".configure" do
    it "allows setting default options" do
      described_class.configure(timeout: 10, check_mx: false)
      expect(described_class.default_options[:timeout]).to eq(10)
      expect(described_class.default_options[:check_mx]).to be false
    end

    it "merges with existing defaults" do
      described_class.configure(timeout: 10)
      expect(described_class.default_options[:timeout]).to eq(10)
      expect(described_class.default_options[:validate_format]).to be true
    end

    it "allows setting test_mode via block" do
      described_class.configure do |config|
        config.test_mode = true
      end
      expect(described_class.test_mode?).to be true
    end

    it "allows setting test_mode via direct assignment" do
      described_class.test_mode = true
      expect(described_class.test_mode?).to be true
      described_class.test_mode = false
      expect(described_class.test_mode?).to be false
    end
  end

  describe ".reset" do
    it "resets to default options" do
      described_class.configure(timeout: 20)
      described_class.reset
      expect(described_class.default_options[:timeout]).to eq(5)
    end

    it "resets test_mode to false" do
      described_class.test_mode = true
      described_class.reset
      expect(described_class.test_mode?).to be false
    end
  end

  describe ".test_mode?" do
    it "returns false by default" do
      described_class.reset
      expect(described_class.test_mode?).to be false
    end

    it "returns true when test_mode is set to true" do
      described_class.test_mode = true
      expect(described_class.test_mode?).to be true
    end
  end

  describe "cache configuration" do
    before do
      described_class.reset
    end

    describe ".cache_enabled?" do
      it "returns true by default" do
        expect(described_class.cache_enabled?).to be true
      end

      it "returns false when cache is disabled" do
        described_class.cache_enabled = false
        expect(described_class.cache_enabled?).to be false
      end

      it "returns true when cache is enabled" do
        described_class.cache_enabled = true
        expect(described_class.cache_enabled?).to be true
      end
    end

    describe ".cache_adapter" do
      it "returns a memory adapter by default" do
        adapter = described_class.cache_adapter
        expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
      end

      it "returns nil when cache is disabled" do
        described_class.cache_enabled = false
        expect(described_class.cache_adapter).to be_nil
      end

      it "returns a memory adapter when cache is enabled" do
        described_class.cache_enabled = true
        adapter = described_class.cache_adapter
        expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
      end

      it "returns the same adapter instance on subsequent calls" do
        described_class.cache_enabled = true
        adapter1 = described_class.cache_adapter
        adapter2 = described_class.cache_adapter
        expect(adapter1).to eq(adapter2)
      end
    end

    describe ".cache_type" do
      it "defaults to :memory" do
        expect(described_class.cache_type).to eq(:memory)
      end

      it "can be set via instance" do
        config = described_class.new
        config.cache_type = :redis
        expect(described_class.cache_type).to eq(:redis)
      end
    end

    describe ".cache_ttl" do
      it "defaults to 3600 seconds" do
        expect(described_class.cache_ttl).to eq(3600)
      end

      it "can be set via instance" do
        config = described_class.new
        config.cache_ttl = 1800
        expect(described_class.cache_ttl).to eq(1800)
      end
    end

    describe ".clear_cache" do
      it "clears the cache when cache is enabled" do
        adapter = described_class.cache_adapter
        adapter.set("test_key", "test_value")
        expect(adapter.get("test_key")).to eq("test_value")

        described_class.clear_cache
        expect(adapter.get("test_key")).to be_nil
      end

      it "does nothing when cache is disabled" do
        described_class.cache_enabled = false
        expect { described_class.clear_cache }.not_to raise_error
      end
    end

    describe ".clear_cache_for_domain" do
      it "clears cache for a specific domain" do
        adapter = described_class.cache_adapter
        adapter.set("mx:example.com", true)
        adapter.set("a:example.com", true)
        adapter.set("mx:other.com", true)

        described_class.clear_cache_for_domain("example.com")

        expect(adapter.get("mx:example.com")).to be_nil
        expect(adapter.get("a:example.com")).to be_nil
        expect(adapter.get("mx:other.com")).to eq(true)
      end

      it "does nothing when cache is disabled" do
        described_class.cache_enabled = false
        expect { described_class.clear_cache_for_domain("example.com") }.not_to raise_error
      end
    end

    describe "cache configuration via block" do
      it "allows setting cache options via configure block" do
        described_class.configure do |config|
          config.cache_enabled = true
          config.cache_ttl = 1800
        end

        expect(described_class.cache_enabled?).to be true
        expect(described_class.cache_ttl).to eq(1800)
      end
    end
  end

  describe "blacklist and whitelist configuration" do
    before do
      described_class.reset
    end

    describe ".blacklist_domains" do
      it "defaults to empty array" do
        expect(described_class.blacklist_domains).to eq([])
      end

      it "can be set via class method" do
        described_class.blacklist_domains = ["spam.com", "blocked.com"]
        expect(described_class.blacklist_domains).to eq(["spam.com", "blocked.com"])
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.blacklist_domains = ["10minutemail.com", /.*\.spam\.com$/]
        end
        expect(described_class.blacklist_domains).to eq(["10minutemail.com", /.*\.spam\.com$/])
      end

      it "resets to empty array" do
        described_class.blacklist_domains = ["spam.com"]
        described_class.reset
        expect(described_class.blacklist_domains).to eq([])
      end
    end

    describe ".whitelist_domains" do
      it "defaults to empty array" do
        expect(described_class.whitelist_domains).to eq([])
      end

      it "can be set via class method" do
        described_class.whitelist_domains = ["example.com", "company.com"]
        expect(described_class.whitelist_domains).to eq(["example.com", "company.com"])
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.whitelist_domains = ["example.com", /.*\.company\.com$/]
        end
        expect(described_class.whitelist_domains).to eq(["example.com", /.*\.company\.com$/])
      end

      it "resets to empty array" do
        described_class.whitelist_domains = ["example.com"]
        described_class.reset
        expect(described_class.whitelist_domains).to eq([])
      end
    end

    describe ".domain_checker" do
      it "defaults to nil" do
        expect(described_class.domain_checker).to be_nil
      end

      it "can be set via class method" do
        checker = lambda { |domain| domain == "allowed.com" }
        described_class.domain_checker = checker
        expect(described_class.domain_checker).to eq(checker)
      end

      it "can be set via configure block" do
        checker = lambda { |domain| domain.length > 5 }
        described_class.configure do |config|
          config.domain_checker = checker
        end
        expect(described_class.domain_checker).to eq(checker)
      end

      it "resets to nil" do
        described_class.domain_checker = lambda { |_domain| true }
        described_class.reset
        expect(described_class.domain_checker).to be_nil
      end
    end
  end

  describe "DNSBL reputation configuration" do
    before do
      described_class.reset
    end

    describe ".check_reputation_lists" do
      it "defaults to false" do
        expect(described_class.check_reputation_lists).to be false
      end

      it "can be set via class method" do
        described_class.check_reputation_lists = true
        expect(described_class.check_reputation_lists).to be true
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.check_reputation_lists = true
        end
        expect(described_class.check_reputation_lists).to be true
      end

      it "resets to false" do
        described_class.check_reputation_lists = true
        described_class.reset
        expect(described_class.check_reputation_lists).to be false
      end
    end

    describe ".reputation_lists" do
      it "defaults to empty array" do
        expect(described_class.reputation_lists).to eq([])
      end

      it "can be set via class method" do
        lists = ["zen.spamhaus.org", "bl.spamcop.net"]
        described_class.reputation_lists = lists
        expect(described_class.reputation_lists).to eq(lists)
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.reputation_lists = ["zen.spamhaus.org"]
        end
        expect(described_class.reputation_lists).to eq(["zen.spamhaus.org"])
      end

      it "resets to empty array" do
        described_class.reputation_lists = ["zen.spamhaus.org"]
        described_class.reset
        expect(described_class.reputation_lists).to eq([])
      end
    end

    describe ".reputation_timeout" do
      it "defaults to 5 seconds" do
        expect(described_class.reputation_timeout).to eq(5)
      end

      it "can be set via class method" do
        described_class.reputation_timeout = 10
        expect(described_class.reputation_timeout).to eq(10)
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.reputation_timeout = 8
        end
        expect(described_class.reputation_timeout).to eq(8)
      end

      it "resets to 5" do
        described_class.reputation_timeout = 10
        described_class.reset
        expect(described_class.reputation_timeout).to eq(5)
      end
    end

    describe ".reputation_fallback_action" do
      it "defaults to :allow" do
        expect(described_class.reputation_fallback_action).to eq(:allow)
      end

      it "can be set via class method" do
        described_class.reputation_fallback_action = :reject
        expect(described_class.reputation_fallback_action).to eq(:reject)
      end

      it "can be set via configure block" do
        described_class.configure do |config|
          config.reputation_fallback_action = :reject
        end
        expect(described_class.reputation_fallback_action).to eq(:reject)
      end

      it "resets to :allow" do
        described_class.reputation_fallback_action = :reject
        described_class.reset
        expect(described_class.reputation_fallback_action).to eq(:allow)
      end
    end

    describe ".clear_cache_for_domain with DNSBL" do
      it "clears DNSBL cache entries when reputation lists are configured" do
        described_class.check_reputation_lists = true
        described_class.reputation_lists = ["zen.spamhaus.org", "bl.spamcop.net"]
        adapter = described_class.cache_adapter
        adapter.set("mx:example.com", true)
        adapter.set("dnsbl:zen.spamhaus.org:example.com", false)
        adapter.set("dnsbl:bl.spamcop.net:example.com", false)
        adapter.set("mx:other.com", true)

        described_class.clear_cache_for_domain("example.com")

        expect(adapter.get("mx:example.com")).to be_nil
        expect(adapter.get("dnsbl:zen.spamhaus.org:example.com")).to be_nil
        expect(adapter.get("dnsbl:bl.spamcop.net:example.com")).to be_nil
        expect(adapter.get("mx:other.com")).to eq(true)
      end
    end
  end
end
