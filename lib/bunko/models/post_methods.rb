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
        before_save :update_word_count, if: :should_update_word_count?
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
        return nil unless word_count.present? && word_count > 0

        (word_count.to_f / Bunko.configuration.reading_speed).ceil
      end

      def reading_time_text
        return nil unless reading_time.present?

        "#{reading_time} min read"
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

      def meta_description_tag
        return nil unless respond_to?(:meta_description) && meta_description.present?

        # Return HTML-safe meta tag string
        require "erb"
        %(<meta name="description" content="#{ERB::Util.html_escape(meta_description)}">).html_safe
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

      def should_update_word_count?
        # Only update word_count if:
        # 1. Auto-update is enabled in config
        # 2. Content changed
        # 3. Model has word_count attribute
        Bunko.configuration.auto_update_word_count &&
          content_changed? &&
          respond_to?(:word_count=)
      end

      def update_word_count
        if content.blank?
          self.word_count = 0
          return
        end

        # Check if content is a text field or JSON field
        column = self.class.columns_hash["content"]

        if column && [:json, :jsonb].include?(column.type)
          # For JSON content, try to extract text recursively
          self.word_count = count_words_in_json(content)
        else
          # For text content, strip HTML tags and count words
          text = content.to_s.gsub(/<[^>]*>/, "")
          self.word_count = text.split(/\s+/).reject(&:blank?).size
        end
      end

      def count_words_in_json(data)
        case data
        when String
          # Strip HTML and count words in string
          text = data.gsub(/<[^>]*>/, "")
          text.split(/\s+/).reject(&:blank?).size
        when Hash
          # Recursively count words in hash values
          data.values.sum { |value| count_words_in_json(value) }
        when Array
          # Recursively count words in array elements
          data.sum { |element| count_words_in_json(element) }
        else
          0
        end
      end
    end
  end
end
