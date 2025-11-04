# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "rspec"
  spec.version       = "3.0.0"
  spec.summary       = "Minimal RSpec stub for offline testing"
  spec.authors       = ["Offline Stub"]
  spec.email         = ["stub@example.com"]
  spec.files         = Dir["lib/**/*.rb", "exe/*"]
  spec.bindir        = "exe"
  spec.executables   = ["rspec"]
  spec.require_paths = ["lib"]
end
