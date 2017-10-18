require "simplecov"
SimpleCov.start

if ENV.key?("CI")
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "pp"
require "bundler/setup"
require "synced_resources"

ENV["RAILS_ENV"] = "test"

if ActionPack::VERSION::MAJOR >= 5
  require "rails-controller-testing"
  Rails::Controller::Testing.install

  def request_params(params)
    { params: params }
  end
else
  def request_params(params)
    params
  end
end

# Load dummy app
require "combustion"
Combustion.path = "spec/dummy"
Combustion.initialize! :all

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  $LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + "/../spec/support")
  require "request_helper"
  config.include RequestHelper

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
