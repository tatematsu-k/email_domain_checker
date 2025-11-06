# EmailDomainChecker

Email address validation and domain checking library to prevent mail server reputation degradation.

## Features

- ✅ Email format validation
- ✅ Domain existence validation
- ✅ MX record checking
- ✅ A record checking
- ✅ Email normalization
- ✅ Domain blacklist/whitelist
- ✅ Custom domain checker
- ✅ ActiveModel/ActiveRecord integration
- ✅ DNS result caching (memory and Redis)
- ✅ Test mode for development

## Quick Example

```ruby
require 'email_domain_checker'

# Quick validation
EmailDomainChecker.valid?("user@example.com", validate_domain: false) # => true

# Domain validation with MX records
EmailDomainChecker.domain_valid?("user@example.com", check_mx: true) # => true/false

# Normalize email
EmailDomainChecker.normalize("User@Example.COM") # => "user@example.com"
```

## Documentation

Please see the [Getting Started](getting-started/installation.md) guide for installation and setup instructions.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
