# Role-Based Address Detection

EmailDomainChecker supports detection and optional rejection of role-based email addresses (e.g., `noreply@`, `admin@`, `support@`). This is useful for distinguishing personal email addresses from automated system addresses, which may not be suitable for certain use cases like user registration or personal communications.

## Overview

Role-based email addresses are commonly used for automated systems and may not be suitable for certain use cases (e.g., user registration, personal communications). This feature helps identify and filter such addresses.

## Configuration

### Basic Usage

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
end

# Role addresses will be rejected
EmailDomainChecker.valid?("noreply@example.com")  # => false
EmailDomainChecker.valid?("admin@example.com")     # => false

# Personal addresses will pass (if they pass other validations)
EmailDomainChecker.valid?("user@example.com")     # => true/false (depends on DNS)
```

### Default Role Addresses

By default, the following role addresses are detected:

- `noreply`, `no-reply`
- `admin`, `administrator`
- `support`, `help`
- `info`, `contact`
- `sales`, `marketing`
- `postmaster`, `abuse`

### Custom Role Addresses

You can customize the list of role addresses to detect:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
  config.role_addresses = ["noreply", "admin", "support", "custom-role"]
end

# Custom role addresses will be rejected
EmailDomainChecker.valid?("custom-role@example.com")  # => false
EmailDomainChecker.valid?("noreply@example.com")       # => false

# Other addresses will pass
EmailDomainChecker.valid?("user@example.com")          # => true/false (depends on DNS)
```

## Detection Behavior

### Case-Insensitive

Role address detection is case-insensitive:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
end

# All of these will be rejected
EmailDomainChecker.valid?("noreply@example.com")   # => false
EmailDomainChecker.valid?("NoReply@example.com")   # => false
EmailDomainChecker.valid?("NOREPLY@example.com")  # => false
```

### Plus Sign Support

Role addresses with plus signs are also detected:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
end

# These will be rejected
EmailDomainChecker.valid?("noreply@example.com")      # => false
EmailDomainChecker.valid?("noreply+tag@example.com")   # => false
EmailDomainChecker.valid?("noreply+123@example.com")    # => false
```

### Dot Separator Support

Role addresses with dot separators are also detected:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
end

# These will be rejected
EmailDomainChecker.valid?("noreply@example.com")        # => false
EmailDomainChecker.valid?("noreply.tag@example.com")    # => false
EmailDomainChecker.valid?("noreply.team@example.com")   # => false
```

## Default Behavior

By default, `reject_role_addresses` is set to `false`, meaning role addresses are not rejected:

```ruby
# Default behavior (reject_role_addresses = false)
EmailDomainChecker.valid?("noreply@example.com")  # => true/false (depends on DNS, not rejected as role address)
```

## Use Cases

### User Registration

Prevent users from registering with role-based addresses:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
end

# In your registration form
email = params[:email]
unless EmailDomainChecker.valid?(email)
  flash[:error] = "Personal email addresses only. Role-based addresses are not allowed."
  return
end
```

### Personal Communications

Ensure only personal email addresses are used for communications:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
  config.role_addresses = ["noreply", "no-reply", "donotreply"]
end

# Check before sending personal messages
if EmailDomainChecker.valid?(recipient_email)
  send_personal_message(recipient_email)
else
  logger.warn("Skipping role-based address: #{recipient_email}")
end
```

### Custom Business Rules

Combine with other validation rules:

```ruby
EmailDomainChecker.configure do |config|
  config.reject_role_addresses = true
  config.role_addresses = ["noreply", "admin", "support"]
  config.blacklist_domains = ["10minutemail.com"]
end

# Both role address and blacklist checks are performed
EmailDomainChecker.valid?("noreply@example.com")        # => false (role address)
EmailDomainChecker.valid?("user@10minutemail.com")     # => false (blacklist)
EmailDomainChecker.valid?("user@example.com")          # => true/false (depends on DNS)
```

## Integration with ActiveModel

When using ActiveModel integration, role address detection is automatically applied:

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { reject_role_addresses: true }
end

# This will fail validation
user = User.new(email: "noreply@example.com")
user.valid?  # => false
user.errors[:email]  # => ["is invalid"]
```

## Notes

- Role address detection is performed **before** format and domain validation
- Detection is case-insensitive
- Supports plus sign (`+`) and dot (`.`) separators after the role address
- Default role addresses can be customized via `role_addresses` configuration
- When `reject_role_addresses` is `false` (default), role addresses are not rejected
