# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load the dummy Rails app
ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"

require "minitest/autorun"
require "active_support/test_case"

# Load support files
Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

# Set up Active Record fixtures and transactional tests
class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Clean database between tests
  teardown do
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == "schema_migrations" || table == "ar_internal_metadata"

      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end

  # Add more helper methods to be used by all tests here...
end
