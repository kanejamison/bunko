# frozen_string_literal: true

module Bunko
  class Configuration
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

    class CollectionCustomizer
      def initialize(collection_hash)
        @collection_hash = collection_hash
      end

      def scope(callable)
        @collection_hash[:scope] = callable
      end

      # Future: Add more customization methods
      # def per_page=(value)
      #   @collection_hash[:per_page] = value
      # end
    end

    attr_accessor :reading_speed, :excerpt_length, :valid_statuses, :post_types, :collections

    def initialize
      @reading_speed = 250 # words per minute
      @excerpt_length = 160 # characters
      @valid_statuses = %w[draft published scheduled]
      @post_types = [] # Must be configured in initializer
      @collections = [] # Multi-type collections
    end

    def post_type(name, &block)
      # Auto-generate slug from name
      generated_slug = name.parameterize

      # Check for conflicts with existing collections
      if collection_exists?(generated_slug)
        raise ArgumentError, "PostType slug '#{generated_slug}' conflicts with existing collection name"
      end

      post_type = {name: name, slug: generated_slug}

      # Allow customization via block
      if block_given?
        customizer = PostTypeCustomizer.new(post_type)
        block.call(customizer)
      end

      @post_types << post_type
    end

    def collection(name, post_types:, &block)
      # Normalize name to slug format
      slug = name.to_s.parameterize

      # Check for conflicts with existing post_types
      if post_type_exists?(slug)
        raise ArgumentError, "Collection name '#{slug}' conflicts with existing PostType slug"
      end

      # Check for conflicts with existing collections
      if collection_exists?(slug)
        raise ArgumentError, "Collection '#{slug}' already exists"
      end

      # Normalize post_types to array of slugs
      normalized_post_types = Array(post_types).map { |pt| pt.to_s.parameterize }

      collection = {
        name: name.to_s,
        slug: slug,
        post_types: normalized_post_types,
        scope: nil
      }

      # Allow customization via block
      if block_given?
        customizer = CollectionCustomizer.new(collection)
        block.call(customizer)
      end

      @collections << collection
    end

    def find_post_type(slug)
      @post_types.find { |pt| pt[:slug] == slug.to_s }
    end

    def find_collection(slug)
      @collections.find { |c| c[:slug] == slug.to_s }
    end

    private

    def post_type_exists?(slug)
      @post_types.any? { |pt| pt[:slug] == slug.to_s }
    end

    def collection_exists?(slug)
      @collections.any? { |c| c[:slug] == slug.to_s }
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
