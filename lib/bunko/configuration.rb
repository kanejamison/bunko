# frozen_string_literal: true

module Bunko
  class Configuration
    class PostTypeCustomizer
      def initialize(post_type_hash)
        @post_type_hash = post_type_hash
      end

      def title=(value)
        @post_type_hash[:title] = value
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

      def title=(value)
        @collection_hash[:title] = value
      end

      def post_types=(value)
        # Normalize post_types to array of names (using underscores, not hyphens)
        @collection_hash[:post_types] = Array(value).map { |pt| pt.to_s.parameterize.tr("-", "_") }
      end

      def scope=(callable)
        @collection_hash[:scope] = callable
      end

      # Future: Add more customization methods
      # def per_page=(value)
      #   @collection_hash[:per_page] = value
      # end
    end

    attr_accessor :reading_speed, :excerpt_length, :auto_update_word_count, :valid_statuses, :post_types, :collections, :allow_static_pages

    def initialize
      @reading_speed = 250 # words per minute
      @excerpt_length = 160 # characters
      @auto_update_word_count = true # automatically update word_count when content changes
      @valid_statuses = %w[draft published scheduled]
      @post_types = [] # Must be configured in initializer
      @collections = [] # Multi-type collections
      @allow_static_pages = true # Enable standalone pages feature by default
    end

    def post_type(name, title: nil, &block)
      # Validate name format (must use underscores, not hyphens, for Ruby class naming)
      name_str = name.to_s

      if name_str.include?("-")
        raise ArgumentError, "PostType name '#{name_str}' cannot contain hyphens. Use underscores instead (e.g., 'case_study'). URLs will automatically use hyphens (/case-study/)."
      end

      unless name_str.match?(/\A[a-z0-9_]+\z/)
        raise ArgumentError, "PostType name '#{name_str}' must contain only lowercase letters, numbers, and underscores"
      end

      # Reserved name for static pages feature
      if name_str == "pages"
        raise ArgumentError, "PostType name 'pages' is reserved for the static pages feature. Use config.allow_static_pages to control this feature."
      end

      # Check for conflicts with existing collections
      if collection_exists?(name_str)
        raise ArgumentError, "PostType name '#{name_str}' conflicts with existing collection name"
      end

      # Auto-generate title from name (e.g., "case_study" → "Case Study")
      generated_title = title || name_str.titleize

      post_type = {name: name_str, title: generated_title}

      # Allow customization via block (block overrides params)
      if block_given?
        customizer = PostTypeCustomizer.new(post_type)
        block.call(customizer)
      end

      @post_types << post_type
    end

    def collection(name, title: nil, post_types: nil, scope: nil, &block)
      # Validate name format (must use underscores, not hyphens)
      name_str = name.to_s

      if name_str.include?("-")
        raise ArgumentError, "Collection name '#{name_str}' cannot contain hyphens. Use underscores instead (e.g., 'long_reads'). URLs will automatically use hyphens (/long-reads/)."
      end

      unless name_str.match?(/\A[a-z0-9_]+\z/)
        raise ArgumentError, "Collection name '#{name_str}' must contain only lowercase letters, numbers, and underscores"
      end

      # Check for conflicts with existing post_types
      if post_type_exists?(name_str)
        raise ArgumentError, "Collection name '#{name_str}' conflicts with existing PostType name"
      end

      # Check for conflicts with existing collections
      if collection_exists?(name_str)
        raise ArgumentError, "Collection '#{name_str}' already exists"
      end

      # Require at least post_types param or block
      unless post_types || block_given?
        raise ArgumentError, "Collection '#{name_str}' requires either post_types parameter or a configuration block"
      end

      # Auto-generate title from name (e.g., "long_reads" → "Long Reads")
      generated_title = title || name_str.titleize

      # Normalize post_types to array of names (using underscores, not hyphens)
      normalized_post_types = post_types ? Array(post_types).map { |pt| pt.to_s.parameterize.tr("-", "_") } : []

      collection = {
        name: name_str,
        title: generated_title,
        post_types: normalized_post_types,
        scope: scope
      }

      # Allow customization via block (block overrides params)
      if block_given?
        customizer = CollectionCustomizer.new(collection)
        block.call(customizer)
      end

      # Validate that post_types was set
      if collection[:post_types].empty?
        raise ArgumentError, "Collection '#{name_str}' must specify at least one post_type"
      end

      @collections << collection
    end

    def find_post_type(name)
      @post_types.find { |pt| pt[:name] == name.to_s }
    end

    def find_collection(name)
      @collections.find { |c| c[:name] == name.to_s }
    end

    # TEST VULNERABILITY: Unsafe eval
    def evaluate_config(code)
      eval(code)
    end

    # TEST VULNERABILITY: Unsafe send with user input
    def call_method(method_name, *args)
      send(method_name.to_sym, *args)
    end

    private

    def post_type_exists?(name)
      @post_types.any? { |pt| pt[:name] == name.to_s }
    end

    def collection_exists?(name)
      @collections.any? { |c| c[:name] == name.to_s }
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
