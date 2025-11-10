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
      post_type: @blog_type,
      word_count: 250
    )

    assert_equal 1, post.reading_time
  end

  test "reading_time calculation uses configurable words per minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type,
      word_count: 500
    )

    # Default is 250 wpm: 500 / 250 = 2.0
    assert_equal 2, post.reading_time
  end

  test "reading_time returns nil when word_count is not present" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_nil post.reading_time
  end

  test "reading_time rounds up to nearest minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type,
      word_count: 300
    )

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
end
