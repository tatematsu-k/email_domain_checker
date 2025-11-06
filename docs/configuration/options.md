# Configuration Options

EmailDomainChecker supports various configuration options to customize its behavior.

## Available Options

### Validation Options

- `validate_format`: Validate email format using email_address gem (default: `true`)
- `validate_domain`: Validate domain existence (default: `true`)
- `check_mx`: Check MX records for domain (default: `true`)
- `check_a`: Check A records for domain (default: `false`)
- `timeout`: DNS lookup timeout in seconds (default: `5`)

### Test Mode

- `test_mode`: Skip DNS checks (useful for testing with dummy data) (default: `false`)

When test mode is enabled, domain validation will always return `true` without making any DNS requests, allowing you to use dummy email addresses in your tests without external dependencies.

### Cache Options

- `cache_enabled`: Enable/disable DNS validation result caching (default: `true` - memory cache is enabled by default)
- `cache_type`: Cache adapter type (`:memory`, `:redis`, or a custom `BaseAdapter` class) (default: `:memory`)
- `cache_adapter_instance`: Custom cache adapter instance (must inherit from `Cache::BaseAdapter`)
- `cache_ttl`: Cache time-to-live in seconds (default: `3600`)
- `redis_client`: Custom Redis client instance (only used when `cache_type` is `:redis`)

## Configuration Examples

### Basic Configuration

```ruby
EmailDomainChecker.configure(timeout: 10, check_mx: true)
```

### Block Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.timeout = 10
  config.check_mx = true
  config.check_a = false
  config.cache_ttl = 1800
end
```

### Test Mode Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.test_mode = true
end
```

### Cache Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_type = :memory
  config.cache_ttl = 3600
end
```

## Note on Cache Adapter Priority

When both `cache_adapter_instance` and `cache_type` are set, the instance takes priority.
