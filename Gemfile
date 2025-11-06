# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in email_domain_checker.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"

# Optional: ActiveModel/ActiveRecord for integration testing
if ENV["ACTIVEMODEL_VERSION"] || ENV["RAILS_VERSION"]
  rails_version = ENV["RAILS_VERSION"]
  activemodel_version = ENV["ACTIVEMODEL_VERSION"]

  # Add required dependencies for older Rails/ActiveModel versions on Ruby 3.4+
  # These gems were removed from Ruby standard library in 3.4+
  if RUBY_VERSION >= "3.4"
    gem "logger"
    gem "mutex_m"
    gem "bigdecimal"
  end

  if rails_version
    gem "rails", "~> #{rails_version}.0"
  elsif activemodel_version
    gem "activemodel", "~> #{activemodel_version}.0"
  end
end
