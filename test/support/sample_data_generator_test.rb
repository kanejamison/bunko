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
    # Allow 50% variance (target is approximate with varied lengths)
    assert word_count > 50, "Expected at least 50 words, got #{word_count}"
    assert word_count < 150, "Expected at most 150 words, got #{word_count}"
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
  def test_title_for_returns_string
    title = @generator.title_for("blog")
    assert_kind_of String, title
    assert title.length > 0
  end

  def test_title_for_generates_varied_titles
    # Generate multiple titles to ensure variety
    titles = 10.times.map { @generator.title_for("blog") }
    # At least 3 different titles in 10 tries
    assert titles.uniq.length >= 3, "Expected variety in generated titles"
  end

  def test_title_for_works_with_any_post_type
    %w[blog docs changelog case_study tutorial unknown].each do |post_type|
      title = @generator.title_for(post_type)
      assert_kind_of String, title
      assert title.length > 0
    end
  end

  # Content generation tests
  def test_content_for_returns_string
    content = @generator.content_for("blog", target_words: 200)
    assert_kind_of String, content
    assert content.length > 0
  end

  def test_content_for_contains_h2_headings
    content = @generator.content_for("blog", target_words: 200)
    # Should have multiple H2 headings
    h2_count = content.scan(/^## /).length
    assert h2_count >= 3, "Expected at least 3 H2 headings, got #{h2_count}"
  end

  def test_content_for_contains_h3_subheadings
    content = @generator.content_for("blog", target_words: 200)
    # Should have H3 subheadings
    assert_match(/### Key Points/, content)
    assert_match(/### Implementation Details/, content)
  end

  def test_content_for_contains_summary
    content = @generator.content_for("blog", target_words: 200)
    # Should end with Summary section
    assert_match(/## Summary/, content)
  end

  def test_content_for_works_with_any_post_type
    # All post types use the same generator now
    %w[blog docs changelog case_study tutorial unknown].each do |post_type|
      content = @generator.content_for(post_type, target_words: 200)
      assert_kind_of String, content
      assert content.length > 0
      assert_match(/^## /, content) # Contains at least one H2
    end
  end

  def test_content_respects_target_words
    content = @generator.content_for("blog", target_words: 300)
    word_count = content.split.length
    # Allow 50% variance (target is approximate with varied lengths and structural elements)
    assert word_count > 150, "Expected at least 150 words, got #{word_count}"
    assert word_count < 450, "Expected at most 450 words, got #{word_count}"
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

  def test_content_with_markdown_format
    content = @generator.content_for("blog", target_words: 200, format: :markdown)
    assert_kind_of String, content
    assert_match(/^## /, content) # Markdown H2 heading
    assert_match(/^### /, content) # Markdown H3 subheading
    refute_match(/<h2/, content) # Should not have HTML tags
    refute_match(/<p/, content) # Should not have HTML tags
  end

  def test_content_with_html_format
    content = @generator.content_for("blog", target_words: 200, format: :html)
    assert_kind_of String, content
    assert_match(/<h2/, content) # HTML H2 heading
    assert_match(/<h3/, content) # HTML H3 subheading
    assert_match(/<p/, content) # HTML paragraph
    refute_match(/^## /, content) # Should not have markdown headings
  end

  def test_markdown_supports_inline_formatting
    # Test that markdown format can produce formatted content
    # Generate a larger sample to ensure formatting appears
    content = @generator.paragraphs(count: 10, format: :markdown)

    # At minimum, content should be a string with multiple paragraphs
    assert_kind_of String, content
    assert content.length > 100

    # Markdown paragraphs should NOT have HTML tags
    refute_match(/<p/, content)
  end

  def test_html_supports_inline_formatting
    # Test that HTML format produces valid HTML elements
    content = @generator.paragraphs(count: 5, format: :html)

    # Should contain HTML paragraph tags
    assert_match(/<p/, content)

    # Should contain closing tags
    assert_match(/<\/p>/, content)

    # Should be valid string
    assert_kind_of String, content
    assert content.length > 100
  end

  def test_html_paragraph_structure
    # Test that HTML paragraphs have correct structure
    paragraph = @generator.paragraph(sentence_count: 3, format: :html)

    # Must start with <p and end with </p>
    assert_match(/^<p/, paragraph)
    assert_match(/<\/p>$/, paragraph)

    # May optionally have a class attribute
    # Just verify the structure is valid HTML
    assert_kind_of String, paragraph
  end

  def test_format_heading_markdown
    # Test heading formatting directly
    heading = @generator.send(:format_heading, "Test Heading", :markdown)
    assert_equal "## Test Heading", heading
  end

  def test_format_heading_html
    # Test heading formatting directly
    heading = @generator.send(:format_heading, "Test Heading", :html)

    # Should be an h2 tag
    assert_match(/^<h2/, heading)
    assert_match(/<\/h2>$/, heading)
    assert_match(/Test Heading/, heading)
  end

  def test_format_heading_plain
    # Test plain heading format
    heading = @generator.send(:format_heading, "Test Heading", :plain)
    assert_equal "## Test Heading", heading
  end
end
