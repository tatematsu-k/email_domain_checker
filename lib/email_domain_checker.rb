# frozen_string_literal: true

require_relative "email_domain_checker/version"
require_relative "email_domain_checker/normalizer"
require_relative "email_domain_checker/domain_validator"
require_relative "email_domain_checker/checker"

module EmailDomainChecker
  class Error < StandardError; end
end

