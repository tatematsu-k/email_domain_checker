# frozen_string_literal: true

module EmailAddress
  class Address
    attr_reader :original

    EMAIL_REGEX = /\A[^\s@]+@[^\s@]+\z/.freeze

    def initialize(email)
      @original = email.to_s
      local, domain = extract_parts(@original)
      @local = local
      @domain = domain
    end

    def valid?
      !@local.nil? && !@domain.nil? && EMAIL_REGEX.match?(normalized)
    end

    def normal
      normalized
    end

    def canonical
      return normalized unless gmail?

      canonical_local = @local.gsub('.', '')
      canonical_local = canonical_local.split('+', 2).first
      "#{canonical_local}@gmail.com"
    end

    def redact
      return "" unless @domain

      "***@#{@domain.downcase}"
    end

    def to_s
      @original
    end

    private

    def extract_parts(email)
      parts = email.to_s.strip.split('@', 2)
      return [nil, nil] if parts.length != 2

      local = parts[0]&.strip
      domain = parts[1]&.strip
      return [nil, nil] if local.nil? || local.empty? || domain.nil? || domain.empty?

      [local, domain]
    end

    def normalized
      return "" unless @local && @domain

      "#{@local.downcase}@#{@domain.downcase}"
    end

    def gmail?
      @domain && @domain.casecmp("gmail.com").zero?
    end
  end

  def self.new(email)
    Address.new(email)
  end
end
