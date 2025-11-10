# frozen_string_literal: true

module Bunko
  # Simple sample data generator for creating realistic-looking posts
  # No external dependencies - uses built-in Ruby randomization
  module SampleDataGenerator
    # Word pools for generating varied content
    NOUNS = %w[system interface component module feature service platform application framework
      solution architecture database network security authentication authorization deployment
      integration workflow pipeline process functionality capability performance scalability
      infrastructure configuration management monitoring analytics documentation implementation
      optimization validation testing deployment].freeze

    VERBS = %w[build create develop implement integrate configure optimize enhance improve streamline
      automate manage deploy monitor analyze validate test debug refactor scale maintain
      upgrade migrate extend customize adapt transform modernize accelerate simplify].freeze

    ADJECTIVES = %w[efficient powerful flexible robust scalable secure reliable fast modern advanced
      comprehensive intuitive seamless integrated automated intelligent dynamic responsive
      innovative cutting-edge enterprise production-ready cloud-native distributed].freeze

    TECH_TERMS = %w[API REST GraphQL microservice container orchestration Kubernetes Docker CI/CD
      authentication JWT OAuth serverless lambda function middleware cache Redis
      PostgreSQL MongoDB WebSocket HTTP HTTPS SSL TLS encryption algorithm].freeze

    COMPANIES = %w[TechCorp DataSystems CloudWorks InnovateLabs ScaleUp DevOps Solutions
      Enterprise Digital Ventures Analytics Group Platform Technologies
      NetworkPro SecureBase CodeCraft BuildTools DeployFirst].freeze

    LOREM_WORDS = %w[lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor
      incididunt ut labore et dolore magna aliqua enim ad minim veniam quis nostrud
      exercitation ullamco laboris nisi aliquip ex ea commodo consequat duis aute
      irure in reprehenderit voluptate velit esse cillum fugiat nulla pariatur
      excepteur sint occaecat cupidatat non proident sunt culpa qui officia deserunt
      mollit anim id est laborum].freeze

    class << self
      # Generate a random word from various pools
      def word(type = :general)
        case type
        when :noun then NOUNS.sample
        when :verb then VERBS.sample
        when :adjective then ADJECTIVES.sample
        when :tech then TECH_TERMS.sample
        when :company then COMPANIES.sample
        else LOREM_WORDS.sample
        end
      end

      # Generate a sentence with specified word count
      def sentence(word_count: rand(8..15), capitalize: true)
        words = Array.new(word_count) { LOREM_WORDS.sample }
        sentence = words.join(" ")
        sentence = sentence.capitalize if capitalize
        "#{sentence}."
      end

      # Generate a paragraph with specified sentence count
      def paragraph(sentence_count: rand(4..8))
        Array.new(sentence_count) { sentence }.join(" ")
      end

      # Generate multiple paragraphs
      def paragraphs(count: 3, target_words: nil)
        if target_words
          # Calculate sentences needed (avg 12 words per sentence)
          sentences_needed = (target_words / 12.0).ceil
          # Group into paragraphs (4-8 sentences each)
          paragraph_count = [(sentences_needed / 6.0).ceil, 1].max

          Array.new(paragraph_count) do
            sentences_in_paragraph = [sentences_needed / paragraph_count, 1].max
            paragraph(sentence_count: sentences_in_paragraph)
          end.join("\n\n")
        else
          Array.new(count) { paragraph }.join("\n\n")
        end
      end

      # Generate a company name
      def company_name
        "#{COMPANIES.sample} #{COMPANIES.sample}"
      end

      # Generate a version number
      def version_number
        "#{rand(1..9)}.#{rand(0..20)}.#{rand(0..50)}"
      end

      # Generate a random date in the past
      def past_date(years_ago: 2)
        seconds_ago = rand(0..(years_ago * 365 * 24 * 60 * 60))
        Time.now - seconds_ago
      end

      # Generate a random date in the future
      def future_date(months_ahead: 3)
        seconds_ahead = rand(0..(months_ahead * 30 * 24 * 60 * 60))
        Time.now + seconds_ahead
      end

      # Generate a title based on post type
      def title_for(post_type_name)
        case post_type_name
        when /blog/i
          blog_title
        when /doc/i
          doc_title
        when /changelog|release|version/i
          changelog_title
        when /case.?stud|success|customer/i
          case_study_title
        when /news|announcement/i
          news_title
        when /tutorial|guide/i
          tutorial_title
        when /api|reference/i
          api_title
        else
          generic_title
        end
      end

      # Generate content structure based on post type
      def content_for(post_type_name, target_words:)
        case post_type_name
        when /blog/i
          blog_content(target_words)
        when /doc/i
          doc_content(target_words)
        when /changelog|release|version/i
          changelog_content(target_words)
        when /case.?stud|success|customer/i
          case_study_content(target_words)
        when /tutorial|guide/i
          tutorial_content(target_words)
        else
          default_content(target_words)
        end
      end

      private

      # Title generators
      def blog_title
        [
          "#{VERBS.sample.capitalize} Your #{NOUNS.sample.capitalize} with #{ADJECTIVES.sample.capitalize} #{NOUNS.sample.capitalize}",
          "How to #{VERBS.sample.capitalize} #{ADJECTIVES.sample.capitalize} #{NOUNS.sample.capitalize}",
          "The Complete Guide to #{NOUNS.sample.capitalize} #{NOUNS.sample.capitalize}",
          "Understanding #{ADJECTIVES.sample.capitalize} #{NOUNS.sample.capitalize}",
          "#{rand(5..10)} Ways to #{VERBS.sample.capitalize} Your #{NOUNS.sample.capitalize}"
        ].sample
      end

      def doc_title
        "#{VERBS.sample.capitalize} #{NOUNS.sample} with #{ADJECTIVES.sample} #{NOUNS.sample}"
      end

      def changelog_title
        "Version #{version_number} - #{VERBS.sample.capitalize} #{NOUNS.sample}"
      end

      def case_study_title
        "How #{company_name} #{VERBS.sample} their #{NOUNS.sample}"
      end

      def news_title
        "#{ADJECTIVES.sample.capitalize} #{NOUNS.sample.capitalize} #{VERBS.sample.capitalize}d"
      end

      def tutorial_title
        "A Complete Guide to #{VERBS.sample.capitalize}ing #{NOUNS.sample.capitalize}"
      end

      def api_title
        "#{TECH_TERMS.sample} #{NOUNS.sample.capitalize} Reference"
      end

      def generic_title
        words = Array.new(rand(3..8)) { LOREM_WORDS.sample }
        words.map(&:capitalize).join(" ")
      end

      # Content generators
      def blog_content(target_words)
        [
          paragraphs(target_words: target_words * 0.15),
          paragraphs(target_words: target_words * 0.70),
          "## Conclusion",
          paragraphs(target_words: target_words * 0.15)
        ].join("\n\n")
      end

      def doc_content(target_words)
        section_words = target_words / 4
        [
          "## Overview",
          paragraphs(target_words: section_words),
          "## Getting Started",
          paragraphs(target_words: section_words),
          "## Examples",
          code_example,
          paragraphs(target_words: section_words * 0.5),
          "## Configuration",
          paragraphs(target_words: section_words * 0.5)
        ].join("\n\n")
      end

      def changelog_content(target_words)
        num_items = rand(3..6)
        [
          "## Added",
          num_items.times.map { "- #{VERBS.sample.capitalize} #{ADJECTIVES.sample} #{NOUNS.sample} functionality" }.join("\n"),
          paragraphs(target_words: target_words * 0.2),
          "\n## Fixed",
          num_items.times.map { "- #{sentence(word_count: rand(5..10))}" }.join("\n"),
          paragraphs(target_words: target_words * 0.2),
          "\n## Changed",
          num_items.times.map { "- #{sentence(word_count: rand(5..10))}" }.join("\n"),
          paragraphs(target_words: target_words * 0.2),
          "\n## Improved",
          num_items.times.map { "- #{VERBS.sample.capitalize} #{NOUNS.sample} performance" }.join("\n"),
          paragraphs(target_words: target_words * 0.2)
        ].join("\n")
      end

      def case_study_content(target_words)
        section_words = target_words / 4
        [
          "## The Challenge",
          paragraphs(target_words: section_words),
          "## The Solution",
          paragraphs(target_words: section_words),
          "## The Results",
          "- #{rand(100..500)}% increase in #{NOUNS.sample}",
          "- #{rand(50..200)}% improvement in #{NOUNS.sample}",
          "- #{rand(20..90)}% reduction in #{NOUNS.sample}",
          "- #{rand(2..10)}x faster #{NOUNS.sample} processing",
          paragraphs(target_words: section_words * 0.5),
          "## Conclusion",
          paragraphs(target_words: section_words)
        ].join("\n\n")
      end

      def tutorial_content(target_words)
        step_words = target_words / 5
        [
          "## Prerequisites",
          paragraphs(target_words: step_words),
          "## Step 1: Setup",
          paragraphs(target_words: step_words),
          "## Step 2: Implementation",
          paragraphs(target_words: step_words),
          "## Step 3: Testing",
          paragraphs(target_words: step_words),
          "## Troubleshooting",
          paragraphs(target_words: step_words)
        ].join("\n\n")
      end

      def default_content(target_words)
        num_sections = rand(2..4)
        section_words = target_words / num_sections
        sections = []

        num_sections.times do |i|
          sections << "## #{generic_title}" if i > 0
          sections << paragraphs(target_words: section_words)
        end

        sections.join("\n\n")
      end

      def code_example
        method = VERBS.sample
        obj = NOUNS.sample
        param = NOUNS.sample

        <<~CODE.chomp
          ```ruby
          # #{sentence(word_count: rand(5..8))}
          #{obj} = #{obj.capitalize}.new(#{param}: '#{word(:adjective)}')
          #{obj}.#{method}!
          ```
        CODE
      end
    end
  end
end
