# frozen_string_literal: true

module Bunko
  class PostTypeCustomizer
    def initialize(post_type_hash)
      @post_type_hash = post_type_hash
    end

    def slug=(value)
      @post_type_hash[:slug] = value
    end

    # Future: Add more customization methods
    # def per_page=(value)
    #   @post_type_hash[:per_page] = value
    # end
  end

  class Configuration
    attr_accessor :reading_speed, :valid_statuses, :post_types

    def initialize
      @reading_speed = 250 # words per minute
      @valid_statuses = %w[draft published scheduled]
      @post_types = [] # Must be configured in initializer
    end

    def post_type(name, &block)
      # Auto-generate slug from name
      generated_slug = name.parameterize

      post_type = {name: name, slug: generated_slug}

      # Allow customization via block
      if block_given?
        customizer = PostTypeCustomizer.new(post_type)
        block.call(customizer)
      end

      @post_types << post_type
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
