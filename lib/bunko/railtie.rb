# frozen_string_literal: true

require "rails/railtie"

module Bunko
  class Railtie < Rails::Railtie
    # Extend Rails routing DSL with bunko_collection
    initializer "bunko.routing" do
      ActiveSupport.on_load(:action_controller) do
        require "bunko/routing"
        ActionDispatch::Routing::Mapper.include Bunko::Routing::MapperMethods
      end
    end

    # Install path helper overrides after routes are loaded
    # This allows blog_path(@post) to automatically extract slug
    config.after_initialize do
      require "bunko/helpers/collection_path_helpers"

      # Install helper overrides in both views and controllers
      ActiveSupport.on_load(:action_view) do
        include Bunko::Helpers::CollectionPathHelpers
        Bunko::Helpers::CollectionPathHelpers.install!
      end

      ActiveSupport.on_load(:action_controller) do
        include Bunko::Helpers::CollectionPathHelpers
        Bunko::Helpers::CollectionPathHelpers.install!
      end
    end

    rake_tasks do
      load "tasks/bunko/install.rake"
      load "tasks/bunko/setup.rake"
      load "tasks/bunko/add.rake"
      load "tasks/bunko/sample_data.rake"
    end
  end
end
