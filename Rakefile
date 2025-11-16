# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "standard/rake"

# Load brakeman vendor scan task
load "lib/tasks/brakeman_vendor.rake"

# Prepare test/dummy app before running tests
desc "Prepare test/dummy app (install, migrate, setup)"
task :prepare_dummy do
  dummy_path = "test/dummy"

  puts "Preparing test/dummy app..."

  # Run bunko:install
  Dir.chdir(dummy_path) do
    sh "rake bunko:install RAILS_ENV=test"
  end

  # Run migrations
  Dir.chdir(dummy_path) do
    sh "rake db:migrate RAILS_ENV=test"
  end

  # Run bunko:setup
  Dir.chdir(dummy_path) do
    sh "rake bunko:setup RAILS_ENV=test"
  end

  # Clean test database to avoid conflicts with test fixtures
  Dir.chdir(dummy_path) do
    sh "rake db:test:prepare RAILS_ENV=test"
  end

  puts "✓ test/dummy app ready"
end

# Create test task
Minitest::TestTask.create

# Make test task depend on prepare_dummy
task test: :prepare_dummy

task default: %i[test standard]
