# Domain Filtering

EmailDomainChecker supports domain filtering through blacklist, whitelist, and custom checker functionality. This is useful for blocking disposable email services, restricting domains within organizations, or implementing custom business logic.

## Overview

Domain filtering allows you to:

- **Block specific domains** using a blacklist
- **Allow only specific domains** using a whitelist
- **Implement custom validation logic** using a custom checker function

The validation order is:
1. Whitelist check (if configured, highest priority)
2. Blacklist check
3. Custom checker
4. DNSBL reputation check (if enabled)
5. DNS validation (MX/A records)

## Blacklist

The blacklist allows you to reject specific domains. This is useful for blocking disposable email services or known spam domains.

### Basic Usage

```ruby
EmailDomainChecker.configure do |config|
  config.blacklist_domains = [
    "10minutemail.com",
    "tempmail.com",
    "guerrillamail.com"
  ]
end

# These will be rejected
EmailDomainChecker.valid?("user@10minutemail.com") # => false
EmailDomainChecker.valid?("user@tempmail.com")     # => false

# Other domains will pass (if they pass DNS validation)
EmailDomainChecker.valid?("user@example.com")      # => true/false (depends on DNS)
```

### Regex Patterns

You can use regex patterns to match multiple domains:

```ruby
EmailDomainChecker.configure do |config|
  config.blacklist_domains = [
    /.*\.spam\.com$/,      # Matches any subdomain of spam.com
    /.*temp.*mail.*/i      # Matches domains containing "temp" and "mail" (case-insensitive)
  ]
end

# These will be rejected
EmailDomainChecker.valid?("user@test.spam.com")        # => false
EmailDomainChecker.valid?("user@another.spam.com")    # => false
EmailDomainChecker.valid?("user@tempmail.com")        # => false
```

## Whitelist

The whitelist allows you to allow only specific domains. When a whitelist is configured, **only** domains matching the whitelist will be allowed (whitelist takes precedence over blacklist).

### Basic Usage

```ruby
EmailDomainChecker.configure do |config|
  config.whitelist_domains = [
    "example.com",
    "company.com"
  ]
end

# These will be allowed (if they pass DNS validation)
EmailDomainChecker.valid?("user@example.com")  # => true/false (depends on DNS)
EmailDomainChecker.valid?("user@company.com")  # => true/false (depends on DNS)

# These will be rejected (not in whitelist)
EmailDomainChecker.valid?("user@other.com")    # => false
EmailDomainChecker.valid?("user@gmail.com")    # => false
```

### Regex Patterns

You can use regex patterns in whitelists:

```ruby
EmailDomainChecker.configure do |config|
  config.whitelist_domains = [
    /.*\.company\.com$/,    # Matches any subdomain of company.com
    /.*@.*\.edu$/           # Matches any .edu domain
  ]
end

# These will be allowed
EmailDomainChecker.valid?("user@mail.company.com")  # => true/false (depends on DNS)
EmailDomainChecker.valid?("user@test.company.com")  # => true/false (depends on DNS)
EmailDomainChecker.valid?("user@university.edu")   # => true/false (depends on DNS)
```

### Whitelist Precedence

When both whitelist and blacklist are configured, the whitelist takes precedence:

```ruby
EmailDomainChecker.configure do |config|
  config.whitelist_domains = ["example.com"]
  config.blacklist_domains = ["example.com"]  # Even if in blacklist
end

# Whitelist takes precedence
EmailDomainChecker.valid?("user@example.com")  # => true/false (depends on DNS, but not rejected by blacklist)
```

## Custom Domain Checker

The custom domain checker allows you to implement your own validation logic. This is useful for integrating with external services or implementing complex business rules.

### Basic Usage

```ruby
EmailDomainChecker.configure do |config|
  config.domain_checker = lambda do |domain|
    # Return true to allow, false to reject
    domain.length > 5 && !domain.start_with?("test")
  end
end

EmailDomainChecker.valid?("user@allowed.com")  # => true/false (depends on checker and DNS)
EmailDomainChecker.valid?("user@test.com")    # => false (rejected by custom checker)
```

### Integration with External Services

```ruby
EmailDomainChecker.configure do |config|
  config.domain_checker = lambda do |domain|
    # Check against disposable email service database
    DisposableEmailService.valid?(domain)
  end
end
```

### Combining with Blacklist

```ruby
EmailDomainChecker.configure do |config|
  config.blacklist_domains = ["spam.com"]
  config.domain_checker = lambda do |domain|
    # Custom logic: only allow domains longer than 5 characters
    domain.length > 5
  end
end

# Blacklist is checked first
EmailDomainChecker.valid?("user@spam.com")     # => false (rejected by blacklist)

# Then custom checker
EmailDomainChecker.valid?("user@a.com")       # => false (rejected by custom checker)

# Both checks pass
EmailDomainChecker.valid?("user@allowed.com")  # => true/false (depends on DNS)
```

## Use Cases

### Blocking Disposable Email Services

```ruby
EmailDomainChecker.configure do |config|
  config.blacklist_domains = [
    "10minutemail.com",
    "tempmail.com",
    "guerrillamail.com",
    "mailinator.com",
    /.*temp.*mail.*/i  # Catch variations
  ]
end
```

### Enterprise Domain Restriction

```ruby
EmailDomainChecker.configure do |config|
  config.whitelist_domains = [
    "company.com",
    "partner.com",
    /.*\.company\.com$/  # Allow subdomains
  ]
end
```

### Custom Business Logic

```ruby
EmailDomainChecker.configure do |config|
  config.domain_checker = lambda do |domain|
    # Check against your internal database
    AllowedDomain.exists?(name: domain) ||
    # Or check against external API
    DomainValidationService.check(domain)
  end
end
```

## Notes

- Whitelist takes precedence over blacklist
- Custom checker is evaluated after blacklist but before DNS validation
- All checks are case-sensitive for string matches (use regex with `i` flag for case-insensitive matching)
- Empty arrays are treated as "no filtering" (all domains pass the filter)
- When whitelist is configured and non-empty, only whitelisted domains can pass
