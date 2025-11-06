# Test Mode

When writing tests, you may want to skip DNS checks to avoid external requests. Enable test mode to skip all DNS validations (MX and A record checks).

## Enabling Test Mode

### In spec_helper.rb or test_helper.rb

```ruby
EmailDomainChecker.configure do |config|
  config.test_mode = true
end
```

### In a before block

```ruby
before do
  EmailDomainChecker::Config.test_mode = true
end
```

## Behavior

When test mode is enabled, domain validation will always return `true` without making any DNS requests, allowing you to use dummy email addresses in your tests without external dependencies.

## Example

```ruby
# In spec_helper.rb
EmailDomainChecker.configure do |config|
  config.test_mode = true
end

# In your specs
it "validates email format" do
  expect(EmailDomainChecker.valid?("test@example.com")).to be true
  # Domain validation is skipped, but format validation still works
end
```
