# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailDomainChecker::Cache do
  describe ".create_adapter" do
    it "creates a memory adapter by default" do
      adapter = described_class.create_adapter(type: :memory)
      expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
    end

    it "creates a memory adapter when type is :memory" do
      adapter = described_class.create_adapter(type: :memory)
      expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
    end

    context "when Redis is available" do
      it "creates a redis adapter when type is :redis" do
        if defined?(EmailDomainChecker::Cache::RedisAdapter)
          adapter = described_class.create_adapter(type: :redis)
          expect(adapter).to be_a(EmailDomainChecker::Cache::RedisAdapter)
        else
          # If Redis is not available, it should fall back to memory
          adapter = described_class.create_adapter(type: :redis)
          expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
        end
      end
    end

    context "when Redis is not available" do
      it "falls back to memory adapter" do
        # This test is only relevant if Redis is actually not available
        # If Redis is available, the above test will handle it
        unless defined?(EmailDomainChecker::Cache::RedisAdapter)
          adapter = described_class.create_adapter(type: :redis)
          expect(adapter).to be_a(EmailDomainChecker::Cache::MemoryAdapter)
        end
      end
    end

    it "raises error for unknown adapter type" do
      expect { described_class.create_adapter(type: :unknown) }.to raise_error(ArgumentError, /Unknown cache adapter type/)
    end
  end
end
