# Module-level Convenience Methods

The `EmailDomainChecker` module provides convenient class methods for quick validation and configuration.

## Validation Methods

### `valid?`

Quick validation with optional domain checking:

```ruby
EmailDomainChecker.valid?("user@example.com", validate_domain: false) # => true
EmailDomainChecker.valid?("user@example.com", check_mx: true) # => true/false
```

### `format_valid?`

Validate email format only (skips domain validation):

```ruby
EmailDomainChecker.format_valid?("user@example.com") # => true
EmailDomainChecker.format_valid?("invalid-email") # => false
```

### `domain_valid?`

Validate domain only (skips format validation):

```ruby
EmailDomainChecker.domain_valid?("user@example.com", check_mx: true) # => true/false
EmailDomainChecker.domain_valid?("user@nonexistent.com", check_mx: true) # => false
```

## Utility Methods

### `normalize`

Normalize email address to lowercase:

```ruby
EmailDomainChecker.normalize("User@Example.COM") # => "user@example.com"
```

## Configuration

### Global Configuration

```ruby
EmailDomainChecker.configure(timeout: 10, check_mx: true)
```

### Block Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.test_mode = true
  config.cache_ttl = 3600
  config.cache_enabled = true
end
```

## Cache Management

### Clear All Cache

```ruby
EmailDomainChecker.clear_cache
```

### Clear Cache for Specific Domain

```ruby
EmailDomainChecker.clear_cache_for_domain("example.com")
```

### Using Cache with Blocks

```ruby
# Method 1: Direct access via EmailDomainChecker.cache (recommended)
result = EmailDomainChecker.cache.with("my_key", ttl: 3600) do
  # This block executes only when cache misses
  expensive_computation
end

# Method 2: Using convenience method
result = EmailDomainChecker.with_cache("my_key", ttl: 3600) do
  expensive_computation
end

# Force cache refresh
result = EmailDomainChecker.with_cache("my_key", force: true) do
  # This block always executes
  updated_computation
end
```
