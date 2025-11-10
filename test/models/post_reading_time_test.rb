# frozen_string_literal: true

require_relative "../test_helper"

class PostReadingTimeTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
  end

  test "reading_time returns estimated reading time in minutes when word_count is present" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )
    post.update_column(:word_count, 250)

    assert_equal 1, post.reading_time
  end

  test "reading_time calculation uses configurable words per minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )
    post.update_column(:word_count, 500)

    # Default is 250 wpm: 500 / 250 = 2.0
    assert_equal 2, post.reading_time
  end

  test "reading_time returns nil when word_count is zero" do
    post = Post.create!(
      title: "Test Post",
      content: "",
      post_type: @blog_type
    )

    assert_equal 0, post.word_count
    assert_nil post.reading_time
  end

  test "reading_time rounds up to nearest minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )
    post.update_column(:word_count, 300)

    # 300 words / 250 wpm = 1.2 minutes, should round to 2
    assert_equal 2, post.reading_time
  end

  test "reading_time uses configured reading speed" do
    original_speed = Bunko.configuration.reading_speed

    begin
      Bunko.configuration.reading_speed = 500
      post = Post.new(word_count: 500, post_type: @blog_type)
      assert_equal 1, post.reading_time
    ensure
      Bunko.configuration.reading_speed = original_speed
    end
  end

  test "reading_time_text returns formatted string" do
    post = Post.new(word_count: 500, post_type: @blog_type)
    assert_equal "2 min read", post.reading_time_text
  end

  test "reading_time_text returns nil when reading_time is nil" do
    post = Post.new(post_type: @blog_type)
    assert_nil post.reading_time_text
  end

  test "word_count is automatically set when post is created with text content" do
    post = Post.create!(
      title: "Test Post",
      content: "This is a test with five words",
      post_type: @blog_type
    )

    assert_equal 7, post.word_count
  end

  test "word_count is automatically updated when text content changes" do
    post = Post.create!(
      title: "Test Post",
      content: "Initial content here",
      post_type: @blog_type
    )

    assert_equal 3, post.word_count

    post.update!(content: "This is much longer content with more words")
    assert_equal 8, post.word_count
  end

  test "word_count strips HTML tags before counting" do
    post = Post.create!(
      title: "Test Post",
      content: "<p>This is <strong>bold</strong> text</p>",
      post_type: @blog_type
    )

    # Should count: "This is bold text" = 4 words
    assert_equal 4, post.word_count
  end

  test "word_count is set to 0 when content is blank" do
    post = Post.create!(
      title: "Test Post",
      content: "Some content",
      post_type: @blog_type
    )

    post.update!(content: "")
    assert_equal 0, post.word_count
  end

  test "word_count is not updated when content does not change" do
    post = Post.create!(
      title: "Test Post",
      content: "Test content",
      post_type: @blog_type
    )

    # word_count is automatically set to 2
    assert_equal 2, post.word_count

    # Manually override it
    post.update_column(:word_count, 100)

    # Update something else (not content), word_count should not change
    post.update!(title: "New Title")
    assert_equal 100, post.word_count
  end

  test "word_count automatic updates can be disabled via config" do
    original = Bunko.configuration.auto_update_word_count

    begin
      Bunko.configuration.auto_update_word_count = false

      post = Post.create!(
        title: "Test Post",
        content: "This has five words here",
        post_type: @blog_type
      )

      # Should not be automatically set
      assert_nil post.word_count
    ensure
      Bunko.configuration.auto_update_word_count = original
    end
  end

  test "count_words_in_json handles nested JSON structures" do
    post = Post.new(post_type: @blog_type)

    # Test with nested hash (like TipTap/ProseMirror structure)
    json_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [{"type" => "text", "text" => "Hello world"}]
        },
        {
          "type" => "paragraph",
          "content" => [{"type" => "text", "text" => "This is a test"}]
        }
      ]
    }

    # Counts all text in JSON including structural values
    # "doc" (1) + "paragraph" (1) + "text" (1) + "Hello world" (2) +
    # "paragraph" (1) + "text" (1) + "This is a test" (4) = 11 words
    # Note: For precise word counts with JSON editors, users should
    # set word_count manually or disable auto_update_word_count
    assert_equal 11, post.send(:count_words_in_json, json_content)
  end

  test "count_words_in_json handles arrays" do
    post = Post.new(post_type: @blog_type)

    json_content = ["First sentence", "Second sentence here", "Third"]

    # Should count: 2 + 3 + 1 = 6 words
    assert_equal 6, post.send(:count_words_in_json, json_content)
  end

  test "count_words_in_json strips HTML from text" do
    post = Post.new(post_type: @blog_type)

    json_content = {
      "content" => "<p>This is <strong>bold</strong> text</p>"
    }

    # Should count: "This is bold text" = 4 words
    assert_equal 4, post.send(:count_words_in_json, json_content)
  end
end
