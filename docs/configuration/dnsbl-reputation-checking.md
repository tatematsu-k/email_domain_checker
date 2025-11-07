# DNSBL Reputation Checking

EmailDomainChecker supports DNSBL (DNS-based Blackhole List) reputation checking to validate domains against external reputation databases. This feature helps prevent sending emails to domains known for spam, phishing, or other malicious activities.

## Overview

DNSBL reputation checking allows you to:

- **Check domain reputation** against multiple DNSBL services
- **Block risky domains** before sending emails
- **Improve email deliverability** by avoiding known problematic domains
- **Configure fallback behavior** when DNSBL lookups fail

The validation order is:
1. Whitelist check (if configured)
2. Blacklist check
3. Custom checker
4. DNSBL reputation check (if enabled)
5. DNS validation (MX/A records)

## Supported DNSBL Services

This implementation uses standard DNS queries and does **not require API keys or authentication**. The following services can be used without API keys:

### Services That Work Without API Keys

- **SpamCop**: `bl.spamcop.net` (no API key required)
- **SORBS**: `dnsbl.sorbs.net` (no API key required)
- **Barracuda**: `b.barracudacentral.org` (no API key required)
- **SpamRATS**: `spam.spamrats.com` (no API key required)

### Services Requiring API Keys

- **Spamhaus ZEN**: `zen.spamhaus.org` (requires DQS key for production use)

**Note**: Spamhaus requires a DQS (Data Query Service) key for production use. This library now supports API key authentication for Spamhaus and other DNSBL services. See the [API Key Configuration](#api-key-configuration) section below for details.

**Important**: Always check the terms of service and usage policies of each DNSBL service before using them in production.

## Configuration

### Basic Configuration

Enable DNSBL checking with a service that doesn't require API keys (recommended):

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["bl.spamcop.net"]  # SpamCop (no API key required)
end
```

**Note**: For services that require API keys (like Spamhaus), see the [API Key Configuration](#api-key-configuration) section below.

### Multiple DNSBL Services

Check against multiple reputation databases (recommended for better coverage):

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = [
    "bl.spamcop.net",      # SpamCop (no API key required)
    "dnsbl.sorbs.net",     # SORBS (no API key required)
    "b.barracudacentral.org" # Barracuda (no API key required)
  ]
end
```

### Timeout Configuration

Configure timeout for DNSBL queries:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_timeout = 5  # seconds (default: 5)
end
```

### Fallback Action

Configure behavior when DNSBL lookup fails (timeout, network error, etc.):

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_fallback_action = :allow  # Allow on error (default)
  # or
  config.reputation_fallback_action = :reject  # Reject on error
end
```

**Fallback Actions:**
- `:allow` (default): Treat lookup failures as "not listed" (allow the domain)
- `:reject`: Treat lookup failures as "listed" (reject the domain)

### API Key Configuration

For DNSBL services that require API keys (such as Spamhaus DQS), you can configure API keys per service:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  # Configure API key for Spamhaus
  config.reputation_api_keys = {
    "zen.spamhaus.org" => "your-dqs-key-here"
  }
end
```

**How it works**: The API key is prepended as a subdomain to the DNSBL hostname. For example, with API key `abc123`, the query for `zen.spamhaus.org` becomes `abc123.zen.spamhaus.org`.

**Multiple services with different keys**:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = [
    "zen.spamhaus.org",      # Requires API key
    "bl.spamcop.net"         # No API key needed
  ]
  config.reputation_api_keys = {
    "zen.spamhaus.org" => "your-spamhaus-dqs-key"
    # SpamCop doesn't need an API key, so it's not in the hash
  }
end
```

**Security Note**: Store API keys securely (e.g., environment variables) and never commit them to version control:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_api_keys = {
    "zen.spamhaus.org" => ENV["SPAMHAUS_DQS_KEY"]
  }
end
```

## Usage Examples

### Basic Usage

```ruby
# Enable DNSBL checking
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
end

# Validate email (includes DNSBL check)
EmailDomainChecker.valid?("user@example.com")
# => true (if domain is not listed) or false (if listed)
```

### Checking Specific Domains

```ruby
# Check if a domain is safe (not listed in any DNSBL)
checker = EmailDomainChecker::DnsBlChecker.new(
  reputation_lists: ["zen.spamhaus.org"]
)

checker.safe?("example.com")
# => true (not listed) or false (listed)

checker.listed?("example.com")
# => false (not listed) or true (listed)
```

### Checking Against Specific DNSBL Service

```ruby
checker = EmailDomainChecker::DnsBlChecker.new(
  reputation_lists: ["zen.spamhaus.org", "bl.spamcop.net"]
)

# Check against a specific DNSBL service
checker.listed_in?("example.com", "zen.spamhaus.org")
# => false (not listed) or true (listed)
```

## How DNSBL Checking Works

1. **Query Format**: The domain is reversed and appended to the DNSBL service hostname
   - Domain: `example.com` → Query: `com.example.zen.spamhaus.org`
2. **DNS Lookup**: An A record lookup is performed on the constructed query
3. **Response Handling**:
   - **A record exists**: Domain is listed (unsafe)
   - **NXDOMAIN (no record)**: Domain is not listed (safe)
   - **Timeout/Error**: Uses configured fallback action

## Performance Considerations

- **Caching**: DNSBL results are cached using the same cache infrastructure as DNS validation
- **Parallel Queries**: When multiple DNSBL services are configured, queries are performed in parallel
- **Timeout**: Configure appropriate timeouts to avoid blocking on slow DNSBL services
- **Cache TTL**: DNSBL results are cached with the same TTL as other DNS validation results (default: 3600 seconds)

## Cache Integration

DNSBL results are automatically cached:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.cache_enabled = true
  config.cache_ttl = 3600  # Cache DNSBL results for 1 hour
end

# First call: DNS query + cache result
EmailDomainChecker.valid?("example.com")

# Subsequent calls: Use cached result
EmailDomainChecker.valid?("example.com")
```

Clear DNSBL cache for a specific domain:

```ruby
# Clears all cache entries for the domain (MX, A, DNSBL)
EmailDomainChecker.clear_cache_for_domain("example.com")
```

## Test Mode

DNSBL checks are automatically skipped when test mode is enabled:

```ruby
EmailDomainChecker.configure do |config|
  config.test_mode = true
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
end

# DNSBL check is skipped, returns true
EmailDomainChecker.valid?("example.com")  # => true
```

## Error Handling

### Network Errors

When a DNSBL lookup fails due to network issues:

```ruby
# With :allow fallback (default)
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_fallback_action = :allow
end
# Network error → treated as "not listed" → domain is allowed

# With :reject fallback
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["zen.spamhaus.org"]
  config.reputation_fallback_action = :reject
end
# Network error → treated as "listed" → domain is rejected
```

### Timeout Handling

Configure timeout to prevent long waits:

```ruby
EmailDomainChecker.configure do |config|
  config.check_reputation_lists = true
  config.reputation_lists = ["bl.spamcop.net"]  # Using API key-free service
  config.reputation_timeout = 3  # 3 seconds timeout
  config.reputation_fallback_action = :allow
end
```

## Best Practices

1. **Use Multiple Services**: Check against multiple DNSBL services for better coverage
2. **Choose API Key-Free Services**: For simplicity, use services that don't require API keys (SpamCop, SORBS, etc.)
3. **Set Appropriate Timeouts**: Balance between thoroughness and performance
4. **Use Caching**: Enable caching to reduce DNSBL query load and respect rate limits
5. **Choose Fallback Action**: Consider your use case:
   - `:allow`: Better for high-volume scenarios where occasional false negatives are acceptable
   - `:reject`: Better for security-sensitive scenarios where false positives are preferred
6. **Monitor Performance**: DNSBL checks add latency; monitor and optimize as needed
7. **Respect Rate Limits**: Even without API keys, services may have rate limits; use caching to minimize queries
8. **Check Terms of Service**: Always review and comply with each DNSBL service's terms of service

## Configuration Options Summary

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `check_reputation_lists` | Boolean | `false` | Enable/disable DNSBL checking |
| `reputation_lists` | Array | `[]` | List of DNSBL service hostnames |
| `reputation_timeout` | Integer | `5` | Timeout for DNSBL queries in seconds |
| `reputation_fallback_action` | Symbol | `:allow` | Action on lookup error (`:allow` or `:reject`) |

## Related Documentation

- [Configuration Options](./options.md) - General configuration options
- [Domain Filtering](./domain-filtering.md) - Blacklist/whitelist functionality
- [Cache Configuration](./cache.md) - Caching options
