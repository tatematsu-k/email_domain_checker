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
  end

  describe ".reset" do
    it "resets to default options" do
      described_class.configure(timeout: 20)
      described_class.reset
      expect(described_class.default_options[:timeout]).to eq(5)
    end
  end
end

