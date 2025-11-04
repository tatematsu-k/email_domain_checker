# frozen_string_literal: true

require_relative "lib/email_domain_checker/version"

Gem::Specification.new do |spec|
  spec.name          = "email_domain_checker"
  spec.version       = EmailDomainChecker::VERSION
  spec.authors       = ["Koki Tatematsu"]
  spec.email         = ["koki.tatematsu@gmail.com"]

  spec.summary       = "Email address validation and domain checking library"
  spec.description   = "A library to validate email addresses and check domain validity to prevent mail server reputation degradation"
  spec.homepage      = "https://github.com/tatematsu-k/email_domain_checker"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "email_address", "~> 0.2"
  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
