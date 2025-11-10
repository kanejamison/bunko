# frozen_string_literal: true

require_relative "../test_helper"

class PostMethodsUnitTest < ActiveSupport::TestCase
  def setup
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
  end

  test "should_generate_slug? returns true when slug is blank and title is present" do
    post = Post.new(title: "Test", post_type: @blog_type)
    assert post.send(:should_generate_slug?)
  end

  test "should_generate_slug? returns false when slug is present" do
    post = Post.new(title: "Test", slug: "existing-slug", post_type: @blog_type)
    refute post.send(:should_generate_slug?)
  end

  test "should_generate_slug? returns false when title is blank" do
    post = Post.new(post_type: @blog_type)
    refute post.send(:should_generate_slug?)
  end

  test "generate_slug creates slug from title" do
    post = Post.new(title: "Hello World", post_type: @blog_type)
    post.send(:generate_slug)
    assert_equal "hello-world", post.slug
  end

  test "generate_slug handles special characters" do
    post = Post.new(title: "Hello & Goodbye!", post_type: @blog_type)
    post.send(:generate_slug)
    assert_equal "hello-goodbye", post.slug
  end

  test "generate_slug adds random suffix when slug exists" do
    existing = Post.create!(
      title: "Test Post",
      slug: "test-post",
      post_type: @blog_type,
      status: "draft"
    )

    post = Post.new(title: "Test Post", post_type: @blog_type)
    post.send(:generate_slug)

    assert_match /^test-post-[a-f0-9]{8}$/, post.slug
    refute_equal "test-post", post.slug
  end

  test "generate_slug returns early if title is blank" do
    post = Post.new(post_type: @blog_type)
    post.send(:generate_slug)
    assert_nil post.slug
  end

  test "should_set_published_at? returns true when status is published and published_at is blank" do
    post = Post.new(status: "published", post_type: @blog_type)
    assert post.send(:should_set_published_at?)
  end

  test "should_set_published_at? returns false when status is not published" do
    post = Post.new(status: "draft", post_type: @blog_type)
    refute post.send(:should_set_published_at?)
  end

  test "should_set_published_at? returns false when published_at is already set" do
    post = Post.new(status: "published", published_at: 1.day.ago, post_type: @blog_type)
    refute post.send(:should_set_published_at?)
  end

  test "set_published_at sets published_at to current time" do
    travel_to Time.zone.local(2025, 1, 1, 12, 0, 0) do
      post = Post.new(status: "published", post_type: @blog_type)
      post.send(:set_published_at)
      assert_equal Time.current, post.published_at
    end
  end

  test "validate_status_value raises error for invalid status" do
    post = Post.new(status: "invalid", post_type: @blog_type)

    error = assert_raises(ArgumentError) do
      post.send(:validate_status_value)
    end

    assert_match /invalid is not a valid status/, error.message
  end

  test "validate_status_value does not raise error for valid status" do
    post = Post.new(status: "published", post_type: @blog_type)
    assert_nothing_raised do
      post.send(:validate_status_value)
    end
  end

  test "validate_status_value returns early if status is blank" do
    post = Post.new(post_type: @blog_type)
    assert_nothing_raised do
      post.send(:validate_status_value)
    end
  end

  test "reading_time returns nil when word_count is not present" do
    post = Post.new(post_type: @blog_type)
    assert_nil post.reading_time
  end

  test "reading_time calculates correctly with default reading speed" do
    post = Post.new(word_count: 250, post_type: @blog_type)
    assert_equal 1, post.reading_time
  end

  test "reading_time rounds up to nearest minute" do
    post = Post.new(word_count: 251, post_type: @blog_type)
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

  test "to_param returns slug" do
    post = Post.new(slug: "my-post", post_type: @blog_type)
    assert_equal "my-post", post.to_param
  end
end
