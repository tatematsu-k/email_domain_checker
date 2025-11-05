# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Cache::MemoryAdapter do
  let(:adapter) { described_class.new }

  describe "#set and #get" do
    it "stores and retrieves values" do
      adapter.set("key1", "value1")
      expect(adapter.get("key1")).to eq("value1")
    end

    it "returns nil for non-existent keys" do
      expect(adapter.get("nonexistent")).to be_nil
    end

    it "overwrites existing values" do
      adapter.set("key1", "value1")
      adapter.set("key1", "value2")
      expect(adapter.get("key1")).to eq("value2")
    end
  end

  describe "#set with TTL" do
    it "expires values after TTL" do
      adapter.set("key1", "value1", ttl: 1)
      expect(adapter.get("key1")).to eq("value1")

      sleep 1.1

      expect(adapter.get("key1")).to be_nil
    end

    it "does not expire values without TTL" do
      adapter.set("key1", "value1")
      sleep 0.1
      expect(adapter.get("key1")).to eq("value1")
    end
  end

  describe "#delete" do
    it "removes keys from cache" do
      adapter.set("key1", "value1")
      adapter.delete("key1")
      expect(adapter.get("key1")).to be_nil
    end

    it "does not raise error for non-existent keys" do
      expect { adapter.delete("nonexistent") }.not_to raise_error
    end
  end

  describe "#clear" do
    it "removes all keys from cache" do
      adapter.set("key1", "value1")
      adapter.set("key2", "value2")
      adapter.clear
      expect(adapter.get("key1")).to be_nil
      expect(adapter.get("key2")).to be_nil
    end
  end

  describe "#exists?" do
    it "returns true for existing keys" do
      adapter.set("key1", "value1")
      expect(adapter.exists?("key1")).to be true
    end

    it "returns false for non-existent keys" do
      expect(adapter.exists?("nonexistent")).to be false
    end

    it "returns false for expired keys" do
      adapter.set("key1", "value1", ttl: 0.1)
      expect(adapter.exists?("key1")).to be true

      sleep 0.2

      expect(adapter.exists?("key1")).to be false
    end
  end

  describe "#size" do
    it "returns the number of cached entries" do
      expect(adapter.size).to eq(0)
      adapter.set("key1", "value1")
      expect(adapter.size).to eq(1)
      adapter.set("key2", "value2")
      expect(adapter.size).to eq(2)
    end

    it "excludes expired entries" do
      adapter.set("key1", "value1", ttl: 0.1)
      adapter.set("key2", "value2")
      expect(adapter.size).to eq(2)

      sleep 0.2

      expect(adapter.size).to eq(1)
    end
  end
end
