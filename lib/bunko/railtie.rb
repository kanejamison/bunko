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

    rake_tasks do
      load "tasks/bunko/setup.rake"
      load "tasks/bunko/add.rake"
      load "tasks/bunko/sample_data.rake"
    end
  end
end
