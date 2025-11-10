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

    # Safe external links for sample content
    SAFE_LINKS = [
      {url: "https://github.com/kanejamison/bunko", text: "Bunko on GitHub"},
      {url: "https://rubyonrails.org", text: "Ruby on Rails"},
      {url: "https://www.ruby-lang.org", text: "Ruby Language"},
      {url: "https://rubygems.org", text: "RubyGems"}
    ].freeze

    # Supported content formats
    FORMATS = [:plain, :markdown, :html].freeze

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

      # Generate a sentence with specified word count and optional formatting
      def sentence(word_count: rand(8..15), capitalize: true, format: :plain)
        words = Array.new(word_count) { LOREM_WORDS.sample }
        sentence = words.join(" ")
        sentence = sentence.capitalize if capitalize
        sentence = "#{sentence}."

        # Randomly apply inline formatting (30% chance)
        if format != :plain && rand < 0.3
          sentence = apply_inline_formatting(sentence, format)
        end

        sentence
      end

      # Generate a paragraph with specified sentence count and optional formatting
      def paragraph(sentence_count: rand(4..8), format: :plain)
        text = Array.new(sentence_count) { sentence(format: format) }.join(" ")

        # Wrap in paragraph tags for HTML (20% chance for class)
        if format == :html
          css_class = (rand < 0.2) ? " class=\"content-paragraph\"" : ""
          text = "<p#{css_class}>#{text}</p>"
        end

        text
      end

      # Generate multiple paragraphs with optional formatting
      def paragraphs(count: 3, target_words: nil, format: :plain)
        paras = if target_words
          # Calculate sentences needed (avg 12 words per sentence)
          sentences_needed = (target_words / 12.0).ceil
          # Group into paragraphs (4-8 sentences each)
          paragraph_count = [(sentences_needed / 6.0).ceil, 1].max

          Array.new(paragraph_count) do
            sentences_in_paragraph = [sentences_needed / paragraph_count, 1].max
            paragraph(sentence_count: sentences_in_paragraph, format: format)
          end
        else
          Array.new(count) { paragraph(format: format) }
        end

        # Randomly add special elements (lists, blockquotes, links)
        paras = inject_special_elements(paras, format) if format != :plain

        paras.join("\n\n")
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
      def content_for(post_type_name, target_words:, format: :plain)
        case post_type_name
        when /blog/i
          blog_content(target_words, format)
        when /doc/i
          doc_content(target_words, format)
        when /changelog|release|version/i
          changelog_content(target_words, format)
        when /case.?stud|success|customer/i
          case_study_content(target_words, format)
        when /tutorial|guide/i
          tutorial_content(target_words, format)
        else
          default_content(target_words, format)
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
      def blog_content(target_words, format = :plain)
        heading = format_heading("Conclusion", format)
        [
          paragraphs(target_words: target_words * 0.15, format: format),
          paragraphs(target_words: target_words * 0.70, format: format),
          heading,
          paragraphs(target_words: target_words * 0.15, format: format)
        ].join("\n\n")
      end

      def doc_content(target_words, format = :plain)
        section_words = target_words / 4
        [
          format_heading("Overview", format),
          paragraphs(target_words: section_words, format: format),
          format_heading("Getting Started", format),
          paragraphs(target_words: section_words, format: format),
          format_heading("Examples", format),
          code_example(format),
          paragraphs(target_words: section_words * 0.5, format: format),
          format_heading("Configuration", format),
          paragraphs(target_words: section_words * 0.5, format: format)
        ].join("\n\n")
      end

      def changelog_content(target_words, format = :plain)
        num_items = rand(3..6)
        [
          format_heading("Added", format),
          num_items.times.map { "- #{VERBS.sample.capitalize} #{ADJECTIVES.sample} #{NOUNS.sample} functionality" }.join("\n"),
          paragraphs(target_words: target_words * 0.2, format: format),
          "\n#{format_heading("Fixed", format)}",
          num_items.times.map { "- #{sentence(word_count: rand(5..10), format: format)}" }.join("\n"),
          paragraphs(target_words: target_words * 0.2, format: format),
          "\n#{format_heading("Changed", format)}",
          num_items.times.map { "- #{sentence(word_count: rand(5..10), format: format)}" }.join("\n"),
          paragraphs(target_words: target_words * 0.2, format: format),
          "\n#{format_heading("Improved", format)}",
          num_items.times.map { "- #{VERBS.sample.capitalize} #{NOUNS.sample} performance" }.join("\n"),
          paragraphs(target_words: target_words * 0.2, format: format)
        ].join("\n")
      end

      def case_study_content(target_words, format = :plain)
        section_words = target_words / 4
        [
          format_heading("The Challenge", format),
          paragraphs(target_words: section_words, format: format),
          format_heading("The Solution", format),
          paragraphs(target_words: section_words, format: format),
          format_heading("The Results", format),
          "- #{rand(100..500)}% increase in #{NOUNS.sample}",
          "- #{rand(50..200)}% improvement in #{NOUNS.sample}",
          "- #{rand(20..90)}% reduction in #{NOUNS.sample}",
          "- #{rand(2..10)}x faster #{NOUNS.sample} processing",
          paragraphs(target_words: section_words * 0.5, format: format),
          format_heading("Conclusion", format),
          paragraphs(target_words: section_words, format: format)
        ].join("\n\n")
      end

      def tutorial_content(target_words, format = :plain)
        step_words = target_words / 5
        [
          format_heading("Prerequisites", format),
          paragraphs(target_words: step_words, format: format),
          format_heading("Step 1: Setup", format),
          paragraphs(target_words: step_words, format: format),
          format_heading("Step 2: Implementation", format),
          paragraphs(target_words: step_words, format: format),
          format_heading("Step 3: Testing", format),
          paragraphs(target_words: step_words, format: format),
          format_heading("Troubleshooting", format),
          paragraphs(target_words: step_words, format: format)
        ].join("\n\n")
      end

      def default_content(target_words, format = :plain)
        num_sections = rand(2..4)
        section_words = target_words / num_sections
        sections = []

        num_sections.times do |i|
          sections << format_heading(generic_title, format) if i > 0
          sections << paragraphs(target_words: section_words, format: format)
        end

        sections.join("\n\n")
      end

      def code_example(format = :plain)
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

      # Formatting helpers
      def format_heading(text, format)
        case format
        when :markdown
          "## #{text}"
        when :html
          css_class = (rand < 0.3) ? " class=\"section-heading\"" : ""
          "<h2#{css_class}>#{text}</h2>"
        else
          "## #{text}"
        end
      end

      def apply_inline_formatting(text, format)
        # Pick a random formatting style
        style = [:bold, :italic, :underline].sample

        # Find a word to format (avoid the last word with period)
        words = text.chomp(".").split
        return text if words.length < 3

        word_index = rand(1...(words.length - 1))
        word = words[word_index]

        formatted_word = case format
        when :markdown
          case style
          when :bold then "**#{word}**"
          when :italic then "_#{word}_"
          when :underline then word # Markdown doesn't have underline
          end
        when :html
          case style
          when :bold then "<strong>#{word}</strong>"
          when :italic then "<em>#{word}</em>"
          when :underline then "<u>#{word}</u>"
          end
        else
          word
        end

        words[word_index] = formatted_word
        "#{words.join(" ")}."
      end

      def inject_special_elements(paragraphs, format)
        return paragraphs if paragraphs.length < 2

        # Randomly inject a blockquote (20% chance)
        if rand < 0.2
          quote_index = rand(1...paragraphs.length)
          quote_text = sentence(word_count: rand(10..15), format: format)
          paragraphs.insert(quote_index, format_blockquote(quote_text, format))
        end

        # Randomly inject a list (30% chance)
        if rand < 0.3
          list_index = rand(1...paragraphs.length)
          paragraphs.insert(list_index, format_list(format))
        end

        # Randomly inject a link into one paragraph (40% chance)
        if rand < 0.4 && paragraphs.any?
          link_para_index = rand(0...paragraphs.length)
          paragraphs[link_para_index] = inject_link(paragraphs[link_para_index], format)
        end

        paragraphs
      end

      def format_blockquote(text, format)
        case format
        when :markdown
          "> #{text}"
        when :html
          css_class = (rand < 0.3) ? " class=\"content-quote\"" : ""
          "<blockquote#{css_class}>#{text}</blockquote>"
        else
          text
        end
      end

      def format_list(format)
        items = rand(3..5).times.map { "#{VERBS.sample.capitalize} #{NOUNS.sample}" }

        case format
        when :markdown
          items.map { |item| "- #{item}" }.join("\n")
        when :html
          css_class = (rand < 0.3) ? " class=\"content-list\"" : ""
          list_items = items.map { |item| "<li>#{item}</li>" }.join("\n")
          "<ul#{css_class}>\n#{list_items}\n</ul>"
        else
          items.join(", ")
        end
      end

      def inject_link(text, format)
        link_data = SAFE_LINKS.sample

        case format
        when :markdown
          # Insert link in middle of text
          "#{text} Learn more about [#{link_data[:text]}](#{link_data[:url]})."
        when :html
          # Insert link in middle of text
          "#{text} Learn more about <a href=\"#{link_data[:url]}\">#{link_data[:text]}</a>."
        else
          text
        end
      end
    end
  end
end
