# frozen_string_literal: true

module Bunko
  module Models
    module ActsAs
      extend ActiveSupport::Concern

      class_methods do
        def acts_as_bunko_post
          include Bunko::Models::PostMethods
        end

        def acts_as_bunko_post_type
          include Bunko::Models::PostTypeMethods
        end
      end
    end
  end
end

# Extend ActiveRecord::Base with acts_as methods
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.include Bunko::Models::ActsAs
end
