# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Custom Cache Adapter" do
  before do
    EmailDomainChecker::Config.reset
  end

  after do
    EmailDomainChecker::Config.reset
  end

  describe "using custom adapter instance" do
    let(:custom_adapter) do
      Class.new(EmailDomainChecker::Cache::BaseAdapter) do
        def initialize
          @store = {}
        end

        def get(key)
          @store[key]
        end

        def set(key, value, ttl: nil)
          @store[key] = value
        end

        def delete(key)
          @store.delete(key)
        end

        def clear
          @store.clear
        end
      end.new
    end

    it "allows setting a custom adapter instance" do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_adapter_instance = custom_adapter
      end

      adapter = EmailDomainChecker::Config.cache_adapter
      expect(adapter).to eq(custom_adapter)
    end

    it "uses custom adapter for DNS resolution caching" do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_adapter_instance = custom_adapter
      end

      # Pre-populate cache
      custom_adapter.set("mx:example.com", true, ttl: 3600)

      # Should use custom cache
      result = EmailDomainChecker.domain_valid?("test@example.com", check_mx: true)
      expect(result).to be true
      expect(custom_adapter.get("mx:example.com")).to be true
    end

    it "raises error for invalid adapter instance" do
      expect do
        EmailDomainChecker.configure do |config|
          config.cache_enabled = true
          config.cache_adapter_instance = "invalid"
        end
      end.to raise_error(ArgumentError, /must be an instance of EmailDomainChecker::Cache::BaseAdapter/)
    end
  end

  describe "using custom adapter class" do
    let(:custom_adapter_class) do
      Class.new(EmailDomainChecker::Cache::BaseAdapter) do
        def initialize
          @store = {}
        end

        def get(key)
          @store[key]
        end

        def set(key, value, ttl: nil)
          @store[key] = value
        end

        def delete(key)
          @store.delete(key)
        end

        def clear
          @store.clear
        end
      end
    end

    it "allows setting a custom adapter class via cache_type" do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_type = custom_adapter_class
      end

      adapter = EmailDomainChecker::Config.cache_adapter
      expect(adapter).to be_a(custom_adapter_class)
    end

    it "instantiates custom adapter class automatically" do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_type = custom_adapter_class
      end

      adapter1 = EmailDomainChecker::Config.cache_adapter
      adapter2 = EmailDomainChecker::Config.cache_adapter

      # Should return the same instance (singleton)
      expect(adapter1).to eq(adapter2)
    end

    it "raises error for class that doesn't inherit from BaseAdapter" do
      invalid_class = Class.new

      expect do
        EmailDomainChecker.configure do |config|
          config.cache_enabled = true
          config.cache_type = invalid_class
        end
        EmailDomainChecker::Config.cache_adapter
      end.to raise_error(ArgumentError, /must inherit from EmailDomainChecker::Cache::BaseAdapter/)
    end
  end

  describe "priority: instance over class" do
    let(:custom_instance) do
      Class.new(EmailDomainChecker::Cache::BaseAdapter) do
        def initialize
          @store = {}
        end

        def get(key)
          @store[key]
        end

        def set(key, value, ttl: nil)
          @store[key] = value
        end

        def delete(key)
          @store.delete(key)
        end

        def clear
          @store.clear
        end
      end.new
    end

    let(:custom_class) do
      Class.new(EmailDomainChecker::Cache::BaseAdapter) do
        def initialize
          @store = {}
        end

        def get(key)
          @store[key]
        end

        def set(key, value, ttl: nil)
          @store[key] = value
        end

        def delete(key)
          @store.delete(key)
        end

        def clear
          @store.clear
        end
      end
    end

    it "uses custom instance when both are set" do
      EmailDomainChecker.configure do |config|
        config.cache_enabled = true
        config.cache_type = custom_class
        config.cache_adapter_instance = custom_instance
      end

      adapter = EmailDomainChecker::Config.cache_adapter
      expect(adapter).to eq(custom_instance)
      expect(adapter).not_to be_a(custom_class)
    end
  end
end
