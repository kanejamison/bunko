# frozen_string_literal: true

require "rails/railtie"

module Bunko
  class Railtie < Rails::Railtie
    # Extend Rails routing DSL with bunko_routes
    initializer "bunko.routing" do
      ActiveSupport.on_load(:action_controller) do
        require "bunko/routing"
        ActionDispatch::Routing::Mapper.include Bunko::Routing::MapperMethods
      end
    end

    rake_tasks do
      load "tasks/bunko_tasks.rake"
    end
  end
end
