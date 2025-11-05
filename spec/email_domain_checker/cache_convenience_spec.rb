# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EmailDomainChecker cache convenience methods" do
  before do
    EmailDomainChecker::Config.reset
  end

  after do
    EmailDomainChecker::Config.reset
  end

  describe ".cache" do
    it "returns cache adapter by default" do
      adapter = EmailDomainChecker.cache
      expect(adapter).to be_a(EmailDomainChecker::Cache::BaseAdapter)
    end

    it "returns nil when cache is disabled" do
      EmailDomainChecker::Config.cache_enabled = false
      expect(EmailDomainChecker.cache).to be_nil
    end

    it "returns cache adapter when cache is enabled" do
      EmailDomainChecker::Config.cache_enabled = true
      adapter = EmailDomainChecker.cache
      expect(adapter).to be_a(EmailDomainChecker::Cache::BaseAdapter)
    end

    it "returns the same adapter instance on multiple calls" do
      EmailDomainChecker::Config.cache_enabled = true
      adapter1 = EmailDomainChecker.cache
      adapter2 = EmailDomainChecker.cache
      expect(adapter1).to eq(adapter2)
    end
  end

  describe ".with_cache" do
    before do
      EmailDomainChecker::Config.cache_enabled = true
    end

    it "works like cache.with" do
      result = EmailDomainChecker.with_cache("test_key", ttl: 3600) do
        "cached_value"
      end

      expect(result).to eq("cached_value")
      expect(EmailDomainChecker.cache.get("test_key")).to eq("cached_value")
    end

    it "returns cached value on cache hit" do
      EmailDomainChecker.cache.set("test_key", "cached_value")

      execution_count = 0
      result = EmailDomainChecker.with_cache("test_key") do
        execution_count += 1
        "new_value"
      end

      expect(result).to eq("cached_value")
      expect(execution_count).to eq(0)
    end

    it "forces block execution when force: true" do
      EmailDomainChecker.cache.set("test_key", "old_value")

      result = EmailDomainChecker.with_cache("test_key", force: true) do
        "new_value"
      end

      expect(result).to eq("new_value")
      expect(EmailDomainChecker.cache.get("test_key")).to eq("new_value")
    end

    it "raises error when cache is disabled" do
      EmailDomainChecker::Config.cache_enabled = false

      expect do
        EmailDomainChecker.with_cache("test_key") do
          "value"
        end
      end.to raise_error(ArgumentError, /Cache is not enabled/)
    end

    it "raises error when block is not given" do
      expect do
        EmailDomainChecker.with_cache("test_key")
      end.to raise_error(ArgumentError, /Block is required/)
    end
  end

  describe "usage examples" do
    before do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_ttl = 3600
      end
    end

    it "allows direct cache access via EmailDomainChecker.cache" do
      cache = EmailDomainChecker.cache
      expect(cache).to be_a(EmailDomainChecker::Cache::BaseAdapter)

      result = cache.with("my_key") do
        "result"
      end

      expect(result).to eq("result")
      expect(cache.get("my_key")).to eq("result")
    end

    it "allows using with_cache convenience method" do
      result = EmailDomainChecker.with_cache("my_key", ttl: 1800) do
        "result"
      end

      expect(result).to eq("result")
      expect(EmailDomainChecker.cache.get("my_key")).to eq("result")
    end
  end
end
