# frozen_string_literal: true

module Bunko
  module Models
    module PostMethods
      extend ActiveSupport::Concern

      included do
        # Associations
        belongs_to :post_type

        # Validations
        validates :title, presence: true
        validates :slug, presence: true, uniqueness: {scope: :post_type_id}
        validates :status, presence: true, inclusion: {
          in: ->(_) { Bunko.configuration.valid_statuses },
          message: "%{value} is not a valid status"
        }

        # Callbacks
        before_validation :generate_slug, if: :should_generate_slug?
        before_validation :set_published_at, if: :should_set_published_at?
        validate :validate_status_value

        # Scopes
        scope :published, -> { where(status: "published").where("published_at <= ?", Time.current).order(published_at: :desc) }
        scope :draft, -> { where(status: "draft").order(created_at: :desc) }
        scope :scheduled, -> { where(status: "published").where("published_at > ?", Time.current).order(published_at: :asc) }

        # Default scope for ordering
        default_scope { order(created_at: :desc) }
      end

      class_methods do
        def by_post_type(type_slug)
          joins(:post_type).where(post_types: {slug: type_slug})
        end
      end

      # Instance methods
      def to_param
        slug
      end

      def reading_time
        return nil unless word_count.present?

        (word_count.to_f / Bunko.configuration.reading_speed).ceil
      end

      private

      def should_generate_slug?
        slug.blank? && title.present?
      end

      def generate_slug
        return if title.blank?

        base_slug = title.parameterize
        self.slug = base_slug

        # Ensure uniqueness within post_type
        return unless self.class.unscoped.where(
          post_type_id: post_type_id,
          slug: slug
        ).where.not(id: id).exists?

        # Add random suffix if slug exists
        self.slug = "#{base_slug}-#{SecureRandom.hex(4)}"
      end

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
