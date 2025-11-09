# frozen_string_literal: true

module Bunko
  module Models
    module PostTypeMethods
      extend ActiveSupport::Concern

      included do
        # Associations
        has_many :posts, dependent: :destroy

        # Validations
        validates :name, presence: true
        validates :slug, presence: true, uniqueness: true
      end
    end
  end
end
