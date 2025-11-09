# frozen_string_literal: true

require "rails/railtie"

module Bunko
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/bunko_tasks.rake"
    end
  end
end
