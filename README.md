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

## Quick Start

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

📖 **[Full Documentation](https://tatematsu-k.github.io/email_domain_checker/latest/)** - Complete usage guide, API reference, and examples

## Features

- ✅ Email format validation
- ✅ Domain existence validation
- ✅ MX record checking
- ✅ A record checking
- ✅ Email normalization
- ✅ ActiveModel/ActiveRecord integration
- ✅ DNS result caching (memory and Redis)
- ✅ Test mode for development
- ✅ Role-based email address detection

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Building Documentation Locally

To build and preview the documentation locally:

```bash
# Install Python dependencies
pip install -r requirements.txt

# Start development server (with live reload)
mkdocs serve

# Build static site
mkdocs build
```

The documentation will be available at `http://127.0.0.1:8000` when using `mkdocs serve`. The built files will be in the `site/` directory when using `mkdocs build`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tatematsu-k/email_domain_checker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
