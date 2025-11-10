# frozen_string_literal: true

module Bunko
  module Models
    module PostMethods
      module WordCountable
        extend ActiveSupport::Concern

        included do
          before_save :update_word_count, if: :should_update_word_count?
        end

        private

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
            self.word_count = text.split(/\s+/).count(&:present?)
          end
        end

        def count_words_in_json(data)
          case data
          when String
            # Strip HTML and count words in string
            text = data.gsub(/<[^>]*>/, "")
            text.split(/\s+/).count(&:present?)
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
end
