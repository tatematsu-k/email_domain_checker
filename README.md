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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/email_domain_checker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

