# frozen_string_literal: true

module Bunko
  module Routing
    module MapperMethods
      # Defines routes for a Bunko collection
      #
      # @param collection_name [Symbol] The name identifier for the collection (e.g., :blog, :case_study)
      # @param options [Hash] Routing options
      # @option options [String] :path Custom URL path (default: name with hyphens)
      # @option options [String] :controller Custom controller name (default: name)
      # @option options [Array<Symbol>] :only Actions to route (default: [:index, :show])
      #
      # @example Basic usage
      #   bunko_collection :blog
      #   # Generates: /blog -> blog#index, /blog/:slug -> blog#show
      #
      # @example Custom path
      #   bunko_collection :case_study, path: "case-studies"
      #   # Generates: /case-studies -> case_study#index, /case-studies/:slug -> case_study#show
      #
      # @example Custom controller
      #   bunko_collection :blog, controller: "articles"
      #   # Generates: /blog -> articles#index, /blog/:slug -> articles#show
      #
      def bunko_collection(collection_name, **options)
        # Extract options with defaults
        custom_path = options.delete(:path)
        controller = options.delete(:controller) || collection_name.to_s

        # Smart detection: Collections (multi-type aggregations) only get index routes
        # PostTypes get both index and show routes
        collection_config = Bunko.configuration.find_collection(collection_name.to_s)

        # Default actions: Collections get [:index], PostTypes get [:index, :show]
        # Users can override with :only option
        default_actions = collection_config ? [:index] : [:index, :show]
        actions = options.delete(:only) || default_actions

        # Resource name must use underscores (for path helpers)
        # Path can use hyphens (for URLs)
        if custom_path
          # User provided custom path - use it for URLs, underscored version for resource name
          resource_name = custom_path.to_s.tr("-", "_").to_sym
          path_value = custom_path
        else
          # No custom path - use collection_name for resource name, hyphenate for path
          resource_name = collection_name
          path_value = collection_name.to_s.dasherize
        end

        # Define the routes
        resources resource_name,
          controller: controller,
          path: path_value,
          only: actions,
          param: :slug,
          **options
      end

      # Defines a route for a standalone Bunko page
      #
      # @param page_name [Symbol] The name identifier for the page (e.g., :about, :contact)
      # @param options [Hash] Routing options
      # @option options [String] :path Custom URL path (default: name with hyphens)
      # @option options [String] :controller Custom controller name (default: "pages")
      #
      # @example Basic usage
      #   bunko_page :about
      #   # Generates: GET /about -> pages#show with params[:page] = "about"
      #
      # @example Custom path
      #   bunko_page :about, path: "about-us"
      #   # Generates: GET /about-us -> pages#show with params[:page] = "about"
      #
      # @example Custom controller
      #   bunko_page :contact, controller: "static_pages"
      #   # Generates: GET /contact -> static_pages#show with params[:page] = "contact"
      #
      def bunko_page(page_name, **options)
        # Extract options with defaults
        custom_path = options.delete(:path)
        controller = options.delete(:controller) || "pages"

        # Convert to underscores for Ruby conventions (route name, helpers)
        slug = page_name.to_s.underscore

        # URL path uses hyphens (Rails convention)
        path_value = custom_path || slug.dasherize

        # Route name uses underscores for path helpers (e.g., about_path)
        route_name = slug.to_sym

        # Define single GET route
        # Pass hyphenated slug to match Post.slug format in database
        get path_value,
          to: "#{controller}#show",
          defaults: {page: slug.dasherize},
          as: route_name
      end
    end
  end
end
