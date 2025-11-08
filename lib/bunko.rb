# frozen_string_literal: true

require_relative "bunko/version"
require_relative "bunko/configuration"
require_relative "bunko/post"

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
