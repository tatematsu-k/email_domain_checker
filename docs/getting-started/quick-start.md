# Quick Start

## Basic Usage

```ruby
require 'email_domain_checker'

# Quick validation
EmailDomainChecker.valid?("user@example.com", validate_domain: false) # => true

# Format validation only
EmailDomainChecker.format_valid?("user@example.com") # => true

# Domain validation only
EmailDomainChecker.domain_valid?("user@example.com", check_mx: true) # => true/false

# Normalize email
EmailDomainChecker.normalize("User@Example.COM") # => "user@example.com"
```

## Configure Default Options

```ruby
# Configure default options globally
EmailDomainChecker.configure(timeout: 10, check_mx: true)

# Enable test mode (skips DNS checks)
EmailDomainChecker.configure do |config|
  config.test_mode = true
end
```

## Cache Configuration

Cache is enabled by default (memory cache):

```ruby
# Cache is enabled by default - no configuration needed
# Just use EmailDomainChecker normally and DNS results will be cached

# Customize cache TTL if needed
EmailDomainChecker.configure do |config|
  config.cache_ttl = 1800 # Cache entries expire after 30 minutes
end
```

For production environments, Redis cache is recommended. See [Cache Configuration](../configuration/cache.md) for details.
