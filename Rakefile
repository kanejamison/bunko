# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "standard/rake"

# Load brakeman vendor scan task
load "lib/tasks/brakeman_vendor.rake"

task default: %i[test standard]
