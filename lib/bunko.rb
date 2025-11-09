# frozen_string_literal: true

require_relative "bunko/version"
require_relative "bunko/configuration"
require_relative "bunko/models/post_methods"
require_relative "bunko/models/post_type_methods"
require_relative "bunko/models/acts_as"
require_relative "bunko/controllers/collection"
require_relative "bunko/controllers/acts_as"
require_relative "bunko/railtie" if defined?(Rails::Railtie)

module Bunko
  class Error < StandardError; end
end
