# frozen_string_literal: true

require_relative "post_methods/sluggable"
require_relative "post_methods/word_countable"
require_relative "post_methods/publishable"

module Bunko
  module Models
    module PostMethods
      extend ActiveSupport::Concern

      include Sluggable
      include WordCountable
      include Publishable

      included do
        # Associations
        belongs_to :post_type

        # Validations
        validates :title, presence: true
        validates :slug, presence: true, uniqueness: {scope: :post_type_id}

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

      def excerpt(length: nil, omission: "...")
        return nil unless content.present?

        # Use configured default if length not specified
        length ||= Bunko.configuration.excerpt_length

        # Strip HTML tags if present
        text = content.to_s.gsub(/<[^>]*>/, "")

        # Return full text if shorter than length
        return text if text.length <= length

        # Truncate to word boundary
        truncated = text[0...length]
        last_space = truncated.rindex(" ") || length

        "#{truncated[0...last_space]}#{omission}"
      end

      def published_date(format = :long)
        return nil unless published_at.present?

        I18n.l(published_at, format: format)
      end
    end
  end
end
