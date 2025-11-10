# frozen_string_literal: true

module Bunko
  module Models
    module PostMethods
      module Sluggable
        extend ActiveSupport::Concern

        included do
          before_validation :generate_slug, if: :should_generate_slug?
        end

        private

        def should_generate_slug?
          slug.blank? && title.present?
        end

        def generate_slug
          return if title.blank?

          # Generate slug and clean up any trailing/leading hyphens or underscores
          base_slug = title.parameterize.gsub(/^[-_]+|[-_]+$/, "")
          self.slug = base_slug

          # Ensure uniqueness within post_type
          return unless self.class.unscoped.where(
            post_type_id: post_type_id,
            slug: slug
          ).where.not(id: id).exists?

          # Add random suffix if slug exists
          self.slug = "#{base_slug}-#{SecureRandom.hex(4)}"
        end
      end
    end
  end
end
