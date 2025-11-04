# EmailDomainChecker

Email address validation and domain checking library to prevent mail server reputation degradation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'email_domain_checker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install email_domain_checker

## Usage

### Module-level convenience methods

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

# Configure default options globally
EmailDomainChecker.configure(timeout: 10, check_mx: true)
```

### Using Checker class

```ruby
require 'email_domain_checker'

# Basic validation
checker = EmailDomainChecker::Checker.new("user@example.com")
if checker.valid?
  puts "Valid email with valid domain"
end

# Check format only
checker = EmailDomainChecker::Checker.new("user@example.com", validate_domain: false)
checker.format_valid? # => true

# Check domain with MX records
checker = EmailDomainChecker::Checker.new("user@example.com", check_mx: true)
checker.domain_valid? # => true if MX records exist

# Get normalized email
checker = EmailDomainChecker::Checker.new("User@Example.COM")
checker.normalized_email # => "user@example.com"

# Get canonical email
checker = EmailDomainChecker::Checker.new("user.name+tag@gmail.com")
checker.canonical_email # => "username@gmail.com"

# Get redacted email (for privacy)
checker = EmailDomainChecker::Checker.new("user@example.com")
checker.redacted_email # => "{hash}@example.com"
```

### ActiveModel / ActiveRecord integration

You can plug the provided validators into any model that uses ActiveModel validations:

```ruby
class User < ApplicationRecord
  validates :email,
            normalize: true,
            domain_check: { check_mx: true, timeout: 3 }
end
```

The `normalize` validator replaces the attribute value with the normalized email address
before the record is validated, and the `domain_check` validator delegates to
`EmailDomainChecker.valid?` while honouring the options you provide.

### Configuration Options

- `validate_format`: Validate email format using email_address gem (default: true)
- `validate_domain`: Validate domain existence (default: true)
- `check_mx`: Check MX records for domain (default: true)
- `check_a`: Check A records for domain (default: false)
- `timeout`: DNS lookup timeout in seconds (default: 5)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/email_domain_checker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
