# frozen_string_literal: true

module Bunko
  module Models
    module PostTypeMethods
      extend ActiveSupport::Concern

      included do
        # Associations
        has_many :posts, dependent: :restrict_with_error

        # Validations
        validates :name, presence: true, uniqueness: true
        validates :title, presence: true
      end
    end
  end
end
