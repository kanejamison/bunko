# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "standard/rake"

# Load brakeman task for security scanning
load "lib/tasks/brakeman.rake"

task default: %i[test standard]
