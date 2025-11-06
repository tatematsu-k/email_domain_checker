# Using Checker Class

The `EmailDomainChecker::Checker` class provides a more object-oriented approach to email validation.

## Basic Usage

```ruby
require 'email_domain_checker'

# Basic validation
checker = EmailDomainChecker::Checker.new("user@example.com")
if checker.valid?
  puts "Valid email with valid domain"
end
```

## Validation Methods

### Format Validation Only

```ruby
checker = EmailDomainChecker::Checker.new("user@example.com", validate_domain: false)
checker.format_valid? # => true
```

### Domain Validation with MX Records

```ruby
checker = EmailDomainChecker::Checker.new("user@example.com", check_mx: true)
checker.domain_valid? # => true if MX records exist
```

## Email Transformations

### Normalized Email

Get the normalized (lowercase) version of the email:

```ruby
checker = EmailDomainChecker::Checker.new("User@Example.COM")
checker.normalized_email # => "user@example.com"
```

### Canonical Email

Get the canonical version of the email (handles Gmail-style aliases):

```ruby
checker = EmailDomainChecker::Checker.new("user.name+tag@gmail.com")
checker.canonical_email # => "username@gmail.com"
```

### Redacted Email

Get a redacted version of the email for privacy (shows hash instead of local part):

```ruby
checker = EmailDomainChecker::Checker.new("user@example.com")
checker.redacted_email # => "{hash}@example.com"
```
