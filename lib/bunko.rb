# frozen_string_literal: true

require_relative "bunko/version"
require_relative "bunko/configuration"
require_relative "bunko/models"
require_relative "bunko/controllers"
require_relative "bunko/railtie" if defined?(Rails::Railtie)

module Bunko
  class Error < StandardError; end
end
