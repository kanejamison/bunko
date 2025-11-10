# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/tasks/support/sample_data_generator"

class SampleDataGeneratorTest < Minitest::Test
  def setup
    @generator = Bunko::SampleDataGenerator
  end

  # Word generation tests
  def test_word_returns_noun
    word = @generator.word(:noun)
    assert @generator::NOUNS.include?(word)
  end

  def test_word_returns_verb
    word = @generator.word(:verb)
    assert @generator::VERBS.include?(word)
  end

  def test_word_returns_adjective
    word = @generator.word(:adjective)
    assert @generator::ADJECTIVES.include?(word)
  end

  def test_word_returns_tech_term
    word = @generator.word(:tech)
    assert @generator::TECH_TERMS.include?(word)
  end

  def test_word_returns_company
    word = @generator.word(:company)
    assert @generator::COMPANIES.include?(word)
  end

  def test_word_returns_lorem_by_default
    word = @generator.word
    assert @generator::LOREM_WORDS.include?(word)
  end

  # Sentence generation tests
  def test_sentence_returns_string
    sentence = @generator.sentence
    assert_kind_of String, sentence
    assert sentence.end_with?(".")
  end

  def test_sentence_respects_word_count
    sentence = @generator.sentence(word_count: 5)
    # Remove period and split
    words = sentence.chomp(".").split
    assert_equal 5, words.length
  end

  def test_sentence_capitalizes_by_default
    sentence = @generator.sentence(word_count: 3, capitalize: true)
    assert sentence[0] == sentence[0].upcase
  end

  # Paragraph generation tests
  def test_paragraph_returns_string
    paragraph = @generator.paragraph
    assert_kind_of String, paragraph
    assert paragraph.length > 0
  end

  def test_paragraph_contains_multiple_sentences
    paragraph = @generator.paragraph(sentence_count: 5)
    # Count periods (one per sentence)
    assert_equal 5, paragraph.count(".")
  end

  # Paragraphs generation tests
  def test_paragraphs_returns_multiple_paragraphs
    text = @generator.paragraphs(count: 3)
    # Paragraphs are separated by double newlines
    assert_equal 3, text.split("\n\n").length
  end

  def test_paragraphs_respects_target_words
    text = @generator.paragraphs(target_words: 100)
    # Rough word count (split by spaces)
    word_count = text.split.length
    # Allow 30% variance (target is approximate)
    assert word_count > 70, "Expected at least 70 words, got #{word_count}"
    assert word_count < 130, "Expected at most 130 words, got #{word_count}"
  end

  # Company name generation tests
  def test_company_name_returns_string
    company = @generator.company_name
    assert_kind_of String, company
    assert company.length > 0
  end

  def test_company_name_contains_two_parts
    company = @generator.company_name
    assert_equal 2, company.split.length
  end

  # Version number generation tests
  def test_version_number_format
    version = @generator.version_number
    assert_match(/^\d+\.\d+\.\d+$/, version)
  end

  # Date generation tests
  def test_past_date_returns_time
    date = @generator.past_date
    assert_kind_of Time, date
  end

  def test_past_date_is_in_past
    date = @generator.past_date
    assert date < Time.now
  end

  def test_past_date_respects_years_ago
    date = @generator.past_date(years_ago: 1)
    one_year_ago = Time.now - (365 * 24 * 60 * 60)
    assert date > one_year_ago, "Date should be within the last year"
  end

  def test_future_date_returns_time
    date = @generator.future_date
    assert_kind_of Time, date
  end

  def test_future_date_is_in_future
    date = @generator.future_date
    assert date > Time.now
  end

  def test_future_date_respects_months_ahead
    date = @generator.future_date(months_ahead: 1)
    one_month_ahead = Time.now + (30 * 24 * 60 * 60)
    assert date < one_month_ahead + (24 * 60 * 60), "Date should be within the next month"
  end

  # Title generation tests
  def test_title_for_blog
    title = @generator.title_for("blog")
    assert_kind_of String, title
    assert title.length > 0
  end

  def test_title_for_docs
    title = @generator.title_for("docs")
    assert_kind_of String, title
    assert title.length > 0
  end

  def test_title_for_changelog
    title = @generator.title_for("changelog")
    assert_kind_of String, title
    assert_match(/Version \d+\.\d+\.\d+/, title)
  end

  def test_title_for_case_study
    title = @generator.title_for("case_study")
    assert_kind_of String, title
    assert_match(/How .+ /, title)
  end

  def test_title_for_tutorial
    title = @generator.title_for("tutorial")
    assert_kind_of String, title
    assert title.length > 0
  end

  def test_title_for_unknown_type
    title = @generator.title_for("unknown")
    assert_kind_of String, title
    assert title.length > 0
  end

  # Content generation tests
  def test_content_for_blog
    content = @generator.content_for("blog", target_words: 200)
    assert_kind_of String, content
    assert_match(/## Conclusion/, content)
  end

  def test_content_for_docs
    content = @generator.content_for("docs", target_words: 200)
    assert_kind_of String, content
    assert_match(/## Overview/, content)
    assert_match(/## Getting Started/, content)
    assert_match(/## Examples/, content)
    assert_match(/## Configuration/, content)
    assert_match(/```ruby/, content)
  end

  def test_content_for_changelog
    content = @generator.content_for("changelog", target_words: 200)
    assert_kind_of String, content
    assert_match(/## Added/, content)
    assert_match(/## Fixed/, content)
    assert_match(/## Changed/, content)
    assert_match(/## Improved/, content)
  end

  def test_content_for_case_study
    content = @generator.content_for("case_study", target_words: 200)
    assert_kind_of String, content
    assert_match(/## The Challenge/, content)
    assert_match(/## The Solution/, content)
    assert_match(/## The Results/, content)
    assert_match(/## Conclusion/, content)
    assert_match(/\d+% increase in/, content)
  end

  def test_content_for_tutorial
    content = @generator.content_for("tutorial", target_words: 200)
    assert_kind_of String, content
    assert_match(/## Prerequisites/, content)
    assert_match(/## Step 1: Setup/, content)
    assert_match(/## Step 2: Implementation/, content)
    assert_match(/## Step 3: Testing/, content)
    assert_match(/## Troubleshooting/, content)
  end

  def test_content_for_unknown_type
    content = @generator.content_for("unknown", target_words: 100)
    assert_kind_of String, content
    assert content.length > 0
  end

  def test_content_respects_target_words
    content = @generator.content_for("blog", target_words: 300)
    word_count = content.split.length
    # Allow 40% variance (target is approximate due to structure)
    assert word_count > 180, "Expected at least 180 words, got #{word_count}"
    assert word_count < 420, "Expected at most 420 words, got #{word_count}"
  end

  # Format-specific tests
  def test_sentence_with_markdown_format
    sentence = @generator.sentence(word_count: 10, format: :markdown)
    assert_kind_of String, sentence
    assert sentence.end_with?(".")
  end

  def test_sentence_with_html_format
    sentence = @generator.sentence(word_count: 10, format: :html)
    assert_kind_of String, sentence
    assert sentence.end_with?(".")
  end

  def test_paragraph_with_markdown_format
    paragraph = @generator.paragraph(sentence_count: 3, format: :markdown)
    assert_kind_of String, paragraph
    assert paragraph.length > 0
  end

  def test_paragraph_with_html_format
    paragraph = @generator.paragraph(sentence_count: 3, format: :html)
    assert_kind_of String, paragraph
    assert_match(/<p/, paragraph) # Should contain paragraph tags
  end

  def test_paragraphs_with_markdown_format
    text = @generator.paragraphs(count: 2, format: :markdown)
    assert_kind_of String, text
    assert text.length > 0
  end

  def test_paragraphs_with_html_format
    text = @generator.paragraphs(count: 2, format: :html)
    assert_kind_of String, text
    assert_match(/<p/, text) # Should contain paragraph tags
  end

  def test_content_for_blog_with_markdown
    content = @generator.content_for("blog", target_words: 200, format: :markdown)
    assert_kind_of String, content
    assert_match(/## Conclusion/, content) # Markdown heading
  end

  def test_content_for_blog_with_html
    content = @generator.content_for("blog", target_words: 200, format: :html)
    assert_kind_of String, content
    assert_match(/<h2/, content) # HTML heading
    assert_match(/<p/, content) # HTML paragraph
  end

  def test_content_for_docs_with_markdown
    content = @generator.content_for("docs", target_words: 200, format: :markdown)
    assert_kind_of String, content
    assert_match(/## Overview/, content)
    assert_match(/## Getting Started/, content)
  end

  def test_content_for_docs_with_html
    content = @generator.content_for("docs", target_words: 200, format: :html)
    assert_kind_of String, content
    assert_match(/<h2/, content)
    assert_match(/<p/, content)
  end

  def test_markdown_bold_formatting
    # Run multiple times since formatting is random
    has_bold = false
    20.times do
      sentence = @generator.sentence(word_count: 10, format: :markdown)
      if sentence.include?("**")
        has_bold = true
        break
      end
    end
    # With 30% chance over 20 tries, we should see at least one bold
    assert has_bold, "Expected to see bold formatting (**text**) in markdown"
  end

  def test_markdown_italic_formatting
    # Run multiple times since formatting is random
    has_italic = false
    20.times do
      sentence = @generator.sentence(word_count: 10, format: :markdown)
      if sentence.match?(/_\w+_/)
        has_italic = true
        break
      end
    end
    # With 30% chance over 20 tries, we should see at least one italic
    assert has_italic, "Expected to see italic formatting (_text_) in markdown"
  end

  def test_html_inline_formatting
    # Run multiple times since formatting is random
    has_formatting = false
    20.times do
      sentence = @generator.sentence(word_count: 10, format: :html)
      if sentence.match?(/<(strong|em|u)>/)
        has_formatting = true
        break
      end
    end
    # With 30% chance over 20 tries, we should see at least one formatted element
    assert has_formatting, "Expected to see HTML inline formatting (<strong>, <em>, or <u>)"
  end

  def test_html_paragraph_classes
    # Run multiple times to check for random classes
    has_class = false
    20.times do
      paragraph = @generator.paragraph(sentence_count: 3, format: :html)
      if paragraph.include?("class=")
        has_class = true
        break
      end
    end
    # With 20% chance over 20 tries, we should see at least one class
    assert has_class, "Expected to see CSS classes on some HTML paragraphs"
  end

  def test_html_heading_classes
    # Run multiple times to check for random classes
    has_class = false
    20.times do
      content = @generator.content_for("blog", target_words: 100, format: :html)
      if content.match?(/<h2[^>]*class="section-heading"/)
        has_class = true
        break
      end
    end
    # With 30% chance on headings over 20 tries, we should see at least one class
    assert has_class, "Expected to see CSS classes on some HTML headings"
  end
end
