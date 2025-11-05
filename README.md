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

# Enable test mode (skips DNS checks)
EmailDomainChecker.configure do |config|
  config.test_mode = true
end

# Cache is enabled by default (memory cache)
# Configure cache settings if needed
EmailDomainChecker.configure do |config|
  config.cache_ttl = 3600 # 1 hour (default)
end

# Disable cache if needed
EmailDomainChecker.configure do |config|
  config.cache_enabled = false
end

# Use Redis cache (requires 'redis' gem)
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_type = :redis
  config.redis_client = Redis.new(url: "redis://localhost:6379")
end
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

### ActiveModel/ActiveRecord Integration

When ActiveModel is available, you can use the `DomainCheckValidator` for easy validation and normalization in your models:

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true, timeout: 3 }, normalize: true
end
```

#### Options

- `domain_check`: Hash of options for domain validation
  - `check_mx`: Check MX records (default: `true`)
  - `check_a`: Check A records (default: `false`)
  - `timeout`: DNS query timeout in seconds (default: `5`)
  - `validate_format`: Validate email format (default: `true`)
  - `validate_domain`: Validate domain (default: `true`)
- `normalize`: Normalize email before validation (default: `false`)
- `message`: Custom error message

#### Examples

```ruby
# Basic validation with domain check
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true, timeout: 3 }
end

# Format validation only (skip domain check)
class User < ActiveRecord::Base
  validates :email, domain_check: { validate_domain: false }
end

# With automatic normalization
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true }, normalize: true
end

# With custom error message
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true }, message: "Invalid email address"
end
```

### Configuration Options

- `validate_format`: Validate email format using email_address gem (default: true)
- `validate_domain`: Validate domain existence (default: true)
- `check_mx`: Check MX records for domain (default: true)
- `check_a`: Check A records for domain (default: false)
- `timeout`: DNS lookup timeout in seconds (default: 5)
- `test_mode`: Skip DNS checks (useful for testing with dummy data) (default: false)
- `cache_enabled`: Enable/disable DNS validation result caching (default: `true` - memory cache is enabled by default)
- `cache_type`: Cache adapter type (`:memory`, `:redis`, or a custom `BaseAdapter` class) (default: `:memory`)
- `cache_adapter_instance`: Custom cache adapter instance (must inherit from `Cache::BaseAdapter`)
- `cache_ttl`: Cache time-to-live in seconds (default: 3600)
- `redis_client`: Custom Redis client instance (only used when `cache_type` is `:redis`)

### Test Mode

When writing tests, you may want to skip DNS checks to avoid external requests. Enable test mode to skip all DNS validations (MX and A record checks):

```ruby
# In spec_helper.rb or test_helper.rb
EmailDomainChecker.configure do |config|
  config.test_mode = true
end

# Or in a before block
before do
  EmailDomainChecker::Config.test_mode = true
end
```

When test mode is enabled, domain validation will always return `true` without making any DNS requests, allowing you to use dummy email addresses in your tests without external dependencies.

### Cache Configuration

DNS validation results are cached by default using in-memory storage to improve performance when validating the same domains multiple times. The cache supports both in-memory storage (default) and Redis (optional).

**Note for production**: While memory cache is enabled by default and works well for development and small applications, we recommend using Redis cache in production environments for better scalability, persistence across application restarts, and shared cache across multiple application instances.

#### Memory Cache (Default - Enabled by Default)

```ruby
# Cache is enabled by default - no configuration needed
# Just use EmailDomainChecker normally and DNS results will be cached

# Customize cache TTL if needed
EmailDomainChecker.configure do |config|
  config.cache_ttl = 1800 # Cache entries expire after 30 minutes
end

# Disable cache if needed
EmailDomainChecker.configure do |config|
  config.cache_enabled = false
end
```

#### Redis Cache (Recommended for Production)

For production environments, Redis cache is recommended for the following reasons:
- **Persistence**: Cache survives application restarts
- **Scalability**: Shared cache across multiple application instances
- **Performance**: Better memory management for large-scale applications
- **Reliability**: Handles cache eviction and expiration more efficiently

To use Redis cache, you need to add the `redis` gem to your Gemfile:

```ruby
gem 'redis'
```

Then configure:

```ruby
# Enable Redis cache
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_type = :redis
  config.cache_ttl = 3600
  config.redis_client = Redis.new(url: "redis://localhost:6379")
end
```

If Redis is not available, the gem will automatically fall back to memory cache.

#### Cache Management

```ruby
# Clear all cached DNS validation results
EmailDomainChecker.clear_cache

# Clear cache for a specific domain
EmailDomainChecker.clear_cache_for_domain("example.com")
```

Cache keys are automatically managed by the gem:
- MX records: `mx:example.com`
- A records: `a:example.com`

#### Using `with` method (Rails-style cache interface)

The cache adapters support a Rails-like `with` method (similar to `Rails.cache.fetch`) for convenient cache access. Cache is enabled by default, so you can use it immediately:

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
result = EmailDomainChecker.cache.with("my_key", force: true) do
  # This block always executes
  updated_computation
end

# Or using convenience method
result = EmailDomainChecker.with_cache("my_key", force: true) do
  updated_computation
end
```

#### Custom Cache Adapter

You can implement your own cache adapter by inheriting from `EmailDomainChecker::Cache::BaseAdapter`:

```ruby
# Define a custom cache adapter
class MyCustomCacheAdapter < EmailDomainChecker::Cache::BaseAdapter
  def initialize
    @store = {} # Your custom storage
  end

  def get(key)
    # Your custom get logic
    @store[key]
  end

  def set(key, value, ttl: nil)
    # Your custom set logic
    @store[key] = value
  end

  def delete(key)
    # Your custom delete logic
    @store.delete(key)
  end

  def clear
    # Your custom clear logic
    @store.clear
  end
end

# Use custom adapter instance
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_adapter_instance = MyCustomCacheAdapter.new
end

# Or use custom adapter class (will be instantiated automatically)
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_type = MyCustomCacheAdapter
end
```

**Note**: When both `cache_adapter_instance` and `cache_type` are set, the instance takes priority.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/email_domain_checker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
