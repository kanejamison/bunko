# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)
require "bunko"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Set the root to the dummy app directory
    config.root = File.expand_path("..", __dir__)

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Disable eager loading in test
    config.eager_load = false

    # Use SQL instead of Active Record's schema dumper
    config.active_record.schema_format = :sql
  end
end
