# Cache Configuration

DNS validation results are cached by default using in-memory storage to improve performance when validating the same domains multiple times. The cache supports both in-memory storage (default) and Redis (optional).

!!! note "Production Recommendation"
    While memory cache is enabled by default and works well for development and small applications, we recommend using Redis cache in production environments for better scalability, persistence across application restarts, and shared cache across multiple application instances.

## Memory Cache (Default - Enabled by Default)

Cache is enabled by default - no configuration needed. Just use EmailDomainChecker normally and DNS results will be cached.

### Customize Cache TTL

```ruby
EmailDomainChecker.configure do |config|
  config.cache_ttl = 1800 # Cache entries expire after 30 minutes
end
```

### Disable Cache

```ruby
EmailDomainChecker.configure do |config|
  config.cache_enabled = false
end
```

## Redis Cache (Recommended for Production)

For production environments, Redis cache is recommended for the following reasons:

- **Persistence**: Cache survives application restarts
- **Scalability**: Shared cache across multiple application instances
- **Performance**: Better memory management for large-scale applications
- **Reliability**: Handles cache eviction and expiration more efficiently

### Setup

First, add the `redis` gem to your Gemfile:

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

!!! tip "Fallback Behavior"
    If Redis is not available, the gem will automatically fall back to memory cache.

## Cache Management

### Clear All Cache

```ruby
# Clear all cached DNS validation results
EmailDomainChecker.clear_cache
```

### Clear Cache for Specific Domain

```ruby
# Clear cache for a specific domain
EmailDomainChecker.clear_cache_for_domain("example.com")
```

### Cache Keys

Cache keys are automatically managed by the gem:

- MX records: `mx:example.com`
- A records: `a:example.com`

## Using `with` Method (Rails-style Cache Interface)

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

## Custom Cache Adapter

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
```

### Using Custom Adapter Instance

```ruby
# Use custom adapter instance
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_adapter_instance = MyCustomCacheAdapter.new
end
```

### Using Custom Adapter Class

```ruby
# Or use custom adapter class (will be instantiated automatically)
EmailDomainChecker.configure do |config|
  config.cache_enabled = true
  config.cache_type = MyCustomCacheAdapter
end
```

!!! note "Priority"
    When both `cache_adapter_instance` and `cache_type` are set, the instance takes priority.
