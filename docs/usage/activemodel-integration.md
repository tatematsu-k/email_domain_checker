# ActiveModel/ActiveRecord Integration

When ActiveModel is available, you can use the `DomainCheckValidator` for easy validation and normalization in your models.

## Basic Usage

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true, timeout: 3 }, normalize: true
end
```

## Validator Options

### `domain_check` Options

Hash of options for domain validation:

- `check_mx`: Check MX records (default: `true`)
- `check_a`: Check A records (default: `false`)
- `timeout`: DNS query timeout in seconds (default: `5`)
- `validate_format`: Validate email format (default: `true`)
- `validate_domain`: Validate domain (default: `true`)

### Other Options

- `normalize`: Normalize email before validation (default: `false`)
- `message`: Custom error message

## Examples

### Basic Validation with Domain Check

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true, timeout: 3 }
end
```

### Format Validation Only

Skip domain check and only validate format:

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { validate_domain: false }
end
```

### With Automatic Normalization

Automatically normalize email addresses before validation:

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true }, normalize: true
end
```

### With Custom Error Message

Provide a custom error message:

```ruby
class User < ActiveRecord::Base
  validates :email, domain_check: { check_mx: true }, message: "Invalid email address"
end
```
