# frozen_string_literal: true

module Bunko
  module Models
    module PostMethods
      module Publishable
        extend ActiveSupport::Concern

        included do
          # Validations
          validates :status, presence: true, inclusion: {
            in: ->(_) { Bunko.configuration.valid_statuses },
            message: "%{value} is not a valid status"
          }

          # Callbacks
          before_validation :set_published_at, if: :should_set_published_at?
          validate :validate_status_value

          # Scopes
          scope :published, -> { where(status: "published").where("published_at <= ?", Time.current).order(published_at: :desc) }
          scope :draft, -> { where(status: "draft").order(created_at: :desc) }
          scope :scheduled, -> { where(status: "published").where("published_at > ?", Time.current).order(published_at: :asc) }
        end

        # Instance method to check if post is scheduled for future publication
        def scheduled?
          status == "published" && published_at.present? && published_at > Time.current
        end

        private

        def should_set_published_at?
          status == "published" && published_at.blank?
        end

        def set_published_at
          self.published_at = Time.current
        end

        def validate_status_value
          return if status.blank?

          unless Bunko.configuration.valid_statuses.include?(status)
            raise ArgumentError, "#{status} is not a valid status"
          end
        end
      end
    end
  end
end
