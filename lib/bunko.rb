# frozen_string_literal: true

require_relative "bunko/version"
require_relative "bunko/configuration"
require_relative "bunko/models/post_methods"
require_relative "bunko/models/post_type_methods"
require_relative "bunko/models/acts_as"
require_relative "bunko/controller"
require_relative "bunko/railtie" if defined?(Rails::Railtie)

module Bunko
  class Error < StandardError; end
end

# Extend ActionController::Base with bunko_collection method
if defined?(ActionController::Base)
  ActionController::Base.class_eval do
    def self.bunko_collection(collection_name, **options)
      include Bunko::Controller
      bunko_collection(collection_name, **options)
    end
  end
end
