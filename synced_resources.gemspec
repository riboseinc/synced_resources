# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "synced_resources/version"

Gem::Specification.new do |spec|
  spec.name          = "synced_resources"
  spec.version       = SyncedResources::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Pagination and synchronization support for Rails"
  spec.description   = "Pagination and synchronization support for Rails"
  spec.homepage      = "https://github.com/riboseinc/synced_resources"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "inherited_resources", "~> 1.7.1"
  spec.add_dependency "responders"
  spec.add_dependency "rails", "~> 5.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rails-controller-testing"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop", "~> 0.49.1"
  spec.add_development_dependency "mysql2", "~> 0.4.9"
  spec.add_development_dependency "sqlite3"
end
