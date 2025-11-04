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
end
