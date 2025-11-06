# frozen_string_literal: true

require "email_address"

module EmailDomainChecker
  class EmailAddressAdapter
    attr_reader :email_address

    def initialize(email)
      @email_address = EmailAddress.new(email)
    end

    def valid?
      email_address.valid?
    end

    def normalized
      email_address.normal
    end

    def canonical
      email_address.canonical
    end

    def redacted
      email_address.redact
    end

    def to_s
      email_address.to_s
    end
  end
end
