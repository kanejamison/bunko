# frozen_string_literal: true

require_relative "../test_helper"

class PostPublishingTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
  end

  test "new post defaults to draft status" do
    post = Post.create!(
      title: "New Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "draft", post.status
    assert_nil post.published_at
  end

  test "changing status to published auto-sets published_at when blank" do
    post = Post.create!(
      title: "Draft Post",
      content: "Content",
      post_type: @blog_type,
      status: "draft"
    )

    assert_nil post.published_at

    post.update!(status: "published")
    assert_not_nil post.published_at
    assert_in_delta Time.current, post.published_at, 2.seconds
  end

  test "published_at is not overwritten if already set" do
    original_time = 1.week.ago
    post = Post.create!(
      title: "Post",
      content: "Content",
      post_type: @blog_type,
      status: "draft",
      published_at: original_time
    )

    post.update!(status: "published")
    assert_equal original_time.to_i, post.published_at.to_i
  end

  test "status can be draft, published, or scheduled" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_nothing_raised do
      post.update!(status: "draft")
      post.update!(status: "published")
      post.update!(status: "scheduled")
    end
  end

  test "invalid status values are rejected" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_raises(ArgumentError) do
      post.update!(status: "invalid_status")
    end
  end

  test "posts with published status but future published_at are treated as scheduled" do
    future_post = Post.create!(
      title: "Future Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.from_now
    )

    assert_includes Post.scheduled, future_post
    refute_includes Post.published, future_post
  end

  test "set_published_at callback sets time to current" do
    travel_to Time.zone.local(2025, 1, 1, 12, 0, 0) do
      post = Post.new(status: "published", post_type: @blog_type)
      post.send(:set_published_at)
      assert_equal Time.current, post.published_at
    end
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

  test "validate_status_value raises error for invalid status" do
    post = Post.new(status: "invalid", post_type: @blog_type)

    error = assert_raises(ArgumentError) do
      post.send(:validate_status_value)
    end

    assert_match(/invalid is not a valid status/, error.message)
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
end
