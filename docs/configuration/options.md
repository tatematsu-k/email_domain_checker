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

### Domain Filtering Options

- `blacklist_domains`: Array of domains to reject (supports strings and regex patterns) (default: `[]`)
- `whitelist_domains`: Array of domains to allow (supports strings and regex patterns) (default: `[]`)
- `domain_checker`: Custom domain validation function (Proc/lambda) (default: `nil`)

When `whitelist_domains` is configured, only domains matching the whitelist will be allowed (whitelist takes precedence over blacklist).

The validation order is:
1. Whitelist check (if configured)
2. Blacklist check
3. Custom checker
4. DNS validation

### Role Address Detection Options

- `reject_role_addresses`: Enable/disable rejection of role-based email addresses (default: `false`)
- `role_addresses`: Array of role addresses to detect (default: `["noreply", "no-reply", "admin", "administrator", "support", "help", "info", "contact", "sales", "marketing", "postmaster", "abuse"]`)

Role address detection is performed before format and domain validation. Detection is case-insensitive and supports plus sign (`+`) and dot (`.`) separators.

### DNSBL Reputation Checking Options

- `check_reputation_lists`: Enable/disable DNSBL reputation checking (default: `false`)
- `reputation_lists`: Array of DNSBL service hostnames (default: `[]`)
- `reputation_timeout`: Timeout for DNSBL queries in seconds (default: `5`)
- `reputation_fallback_action`: Action when DNSBL lookup fails (`:allow` or `:reject`, default: `:allow`)
- `reputation_api_keys`: Hash of API keys for DNSBL services (default: `{}`)

DNSBL (DNS-based Blackhole List) checking validates domains against external reputation databases such as Spamhaus, SpamCop, and SORBS. When enabled, domains listed in any configured DNSBL service will be rejected.

The validation order is:
1. Whitelist check (if configured)
2. Blacklist check
3. Custom checker
4. DNSBL reputation check (if enabled)
5. DNS validation (MX/A records)

See [DNSBL Reputation Checking](./dnsbl-reputation-checking.md) for detailed documentation.

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

### Blacklist Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.blacklist_domains = [
    "10minutemail.com",
    "tempmail.com",
    /.*\.spam\.com$/ # Regex patterns are supported
  ]
end
```

### Whitelist Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.whitelist_domains = [
    "example.com",
    "company.com",
    /.*\.company\.com$/ # Regex patterns are supported
  ]
end
```

### Custom Domain Checker

```ruby
EmailDomainChecker.configure do |config|
  config.domain_checker = lambda do |domain|
    # Custom validation logic
    # Return true to allow, false to reject
    DisposableEmailService.valid?(domain)
  end
end
```

### Role Address Detection Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
  config.role_addresses = ["noreply", "admin", "support"]
end
```

### DNSBL Reputation Checking Configuration

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_timeout = 5
  config.reputation_fallback_action = :allow
  # API key for Spamhaus (if required)
  config.reputation_api_keys = {
    "zen.spamhaus.org" => ENV["SPAMHAUS_DQS_KEY"]
  }
end
```

For multiple DNSBL services:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = [
    "zen.spamhaus.org",
    "bl.spamcop.net",
    "dnsbl.sorbs.net"
  ]
end
```

## Note on Cache Adapter Priority

When both `cache_adapter_instance` and `cache_type` are set, the instance takes priority.
