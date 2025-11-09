# frozen_string_literal: true

module Bunko
  module Routing
    module MapperMethods
      # Defines routes for a Bunko collection
      #
      # @param collection_slug [Symbol] The slug identifier for the collection (e.g., :blog, :case_study)
      # @param options [Hash] Routing options
      # @option options [String] :path Custom URL path (default: slug with hyphens)
      # @option options [String] :controller Custom controller name (default: slug)
      # @option options [Array<Symbol>] :only Actions to route (default: [:index, :show])
      #
      # @example Basic usage
      #   bunko_routes :blog
      #   # Generates: /blog -> blog#index, /blog/:slug -> blog#show
      #
      # @example Custom path
      #   bunko_routes :case_study, path: "case-studies"
      #   # Generates: /case-studies -> case_study#index, /case-studies/:slug -> case_study#show
      #
      # @example Custom controller
      #   bunko_routes :blog, controller: "articles"
      #   # Generates: /blog -> articles#index, /blog/:slug -> articles#show
      #
      def bunko_routes(collection_slug, **options)
        # Extract options with defaults
        custom_path = options.delete(:path)
        controller = options.delete(:controller) || collection_slug.to_s
        actions = options.delete(:only) || [:index, :show]

        # Resource name must use underscores (for path helpers)
        # Path can use hyphens (for URLs)
        if custom_path
          # User provided custom path - use it for URLs, underscored version for resource name
          resource_name = custom_path.to_s.tr("-", "_").to_sym
          path_value = custom_path
        else
          # No custom path - use collection_slug for resource name, hyphenate for path
          resource_name = collection_slug
          path_value = collection_slug.to_s.tr("_", "-")
        end

        # Define the routes
        resources resource_name,
          controller: controller,
          path: path_value,
          only: actions,
          param: :slug,
          **options
      end
    end
  end
end
