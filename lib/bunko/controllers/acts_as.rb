# frozen_string_literal: true

module Bunko
  module Controllers
    module ActsAs
      extend ActiveSupport::Concern

      class_methods do
        def bunko_collection(collection_name, **options)
          include Bunko::Controllers::Collection
          bunko_collection(collection_name, **options)
        end
      end
    end
  end
end

# Extend ActionController::Base with bunko_collection method
if defined?(ActionController::Base)
  ActionController::Base.include Bunko::Controllers::ActsAs
end
