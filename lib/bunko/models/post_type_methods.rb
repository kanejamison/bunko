# frozen_string_literal: true

module Bunko
  module Models
    module PostTypeMethods
      extend ActiveSupport::Concern

      included do
        # Associations
        has_many :posts, dependent: :restrict_with_error

        # Validations
        # Name format mirrors the config DSL rules (Bunko::Configuration#post_type).
        # Enforced at the model level too, since records can be created outside the
        # DSL (console, seeds, admin UIs) and generated views build route helper
        # names from post_type.name.
        validates :name, presence: true, uniqueness: true,
          format: {
            with: /\A[a-z0-9_]+\z/,
            message: "must contain only lowercase letters, numbers, and underscores"
          },
          length: {maximum: 100}
        validates :title, presence: true
      end
    end
  end
end
