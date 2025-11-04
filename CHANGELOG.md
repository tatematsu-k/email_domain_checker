# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-11-04

### Added
- ActiveModel/ActiveRecord validator integration (`DomainCheckValidator`) ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))
- Automatic email normalization option in validator ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))
- Ruby 3.4+ compatibility support for ActiveModel integration ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))
- Comprehensive test coverage for ActiveModel validator ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))

### Changed
- CI: Added ActiveRecord version matrix testing for better compatibility testing ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))

### Documentation
- Added ActiveModel integration documentation with usage examples ([#3](https://github.com/tatematsu-k/email_domain_checker/pull/3))

## [0.1.0] - 2025-11-4

### Added
- Initial release
- Email format validation using `email_address` gem
- Domain validation with MX and A record checks
- Email normalization and canonicalization
- Email redaction for privacy
- Module-level convenience methods
- Configurable default options
- DNS resolver with timeout support
- Comprehensive test coverage

### Features
- `EmailDomainChecker::Checker` class for detailed validation
- `EmailDomainChecker.valid?` for quick validation
- `EmailDomainChecker.format_valid?` for format-only checks
- `EmailDomainChecker.domain_valid?` for domain-only checks
- `EmailDomainChecker.normalize` for email normalization
- `EmailDomainChecker.configure` for global configuration
