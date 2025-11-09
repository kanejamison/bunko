# frozen_string_literal: true

require_relative "bunko/version"
require_relative "bunko/configuration"
require_relative "bunko/post"
require_relative "bunko/controller"
require_relative "bunko/railtie" if defined?(Rails::Railtie)

module Bunko
  class Error < StandardError; end
end

# Extend ActiveRecord::Base with acts_as_bunko_post method
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.class_eval do
    def self.acts_as_bunko_post
      include Bunko::Post
    end
  end
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
