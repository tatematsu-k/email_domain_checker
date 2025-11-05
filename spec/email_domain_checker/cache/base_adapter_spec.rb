# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Cache::BaseAdapter do
  # Use MemoryAdapter as a concrete implementation for testing BaseAdapter methods
  let(:adapter) { EmailDomainChecker::Cache::MemoryAdapter.new }

  describe "#with" do
    it "executes block and caches result when cache miss" do
      execution_count = 0
      result = adapter.with("key1") do
        execution_count += 1
        "result_value"
      end

      expect(result).to eq("result_value")
      expect(execution_count).to eq(1)
      expect(adapter.get("key1")).to eq("result_value")
    end

    it "returns cached value when cache hit" do
      adapter.set("key1", "cached_value")

      execution_count = 0
      result = adapter.with("key1") do
        execution_count += 1
        "new_value"
      end

      expect(result).to eq("cached_value")
      expect(execution_count).to eq(0)
    end

    it "caches result with TTL" do
      adapter.with("key1", ttl: 1) do
        "value_with_ttl"
      end

      expect(adapter.get("key1")).to eq("value_with_ttl")

      sleep 1.1

      expect(adapter.get("key1")).to be_nil
    end

    it "forces block execution when force: true" do
      adapter.set("key1", "old_value")

      result = adapter.with("key1", force: true) do
        "new_value"
      end

      expect(result).to eq("new_value")
      expect(adapter.get("key1")).to eq("new_value")
    end

    it "caches nil values (like Rails cache)" do
      result = adapter.with("key1") do
        nil
      end

      expect(result).to be_nil
      # nil should be cached (like Rails.cache.fetch)
      expect(adapter.get("key1")).to be_nil

      # Second call should use cache
      execution_count = 0
      result2 = adapter.with("key1") do
        execution_count += 1
        "should_not_execute"
      end

      expect(result2).to be_nil
      expect(execution_count).to eq(0)
    end

    it "caches false values" do
      result = adapter.with("key1") do
        false
      end

      expect(result).to be false
      expect(adapter.get("key1")).to be false
    end

    it "raises error when block is not given" do
      expect { adapter.with("key1") }.to raise_error(ArgumentError, /Block is required/)
    end

    it "works with multiple calls" do
      # First call - cache miss
      result1 = adapter.with("key1") do
        "value1"
      end

      # Second call - cache hit
      result2 = adapter.with("key1") do
        "value2"
      end

      expect(result1).to eq("value1")
      expect(result2).to eq("value1") # Should return cached value
      expect(adapter.get("key1")).to eq("value1")
    end
  end
end
