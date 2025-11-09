# frozen_string_literal: true

require_relative "../test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
    @docs_type = PostType.create!(name: "Docs", slug: "docs")
  end

  # Scopes & Queries Tests
  test ".published scope returns only posts with published_at <= current time" do
    # Create published posts
    published_post = Post.create!(
      title: "Published Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    # Create draft post
    draft_post = Post.create!(
      title: "Draft Post",
      content: "Content",
      post_type: @blog_type,
      status: "draft"
    )

    # Create scheduled post (future)
    scheduled_post = Post.create!(
      title: "Scheduled Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.from_now
    )

    published = Post.published
    assert_includes published, published_post
    refute_includes published, draft_post
    refute_includes published, scheduled_post
  end

  test ".draft scope returns only draft posts" do
    draft_post = Post.create!(
      title: "Draft Post",
      content: "Content",
      post_type: @blog_type,
      status: "draft"
    )

    published_post = Post.create!(
      title: "Published Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    drafts = Post.draft
    assert_includes drafts, draft_post
    refute_includes drafts, published_post
  end

  test ".scheduled scope returns posts scheduled for future publication" do
    scheduled_post = Post.create!(
      title: "Scheduled Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.from_now
    )

    published_post = Post.create!(
      title: "Published Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    draft_post = Post.create!(
      title: "Draft Post",
      content: "Content",
      post_type: @blog_type,
      status: "draft"
    )

    scheduled = Post.scheduled
    assert_includes scheduled, scheduled_post
    refute_includes scheduled, published_post
    refute_includes scheduled, draft_post
  end

  test ".by_post_type filters posts by post type" do
    blog_post = Post.create!(
      title: "Blog Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: Time.current
    )

    docs_post = Post.create!(
      title: "Docs Post",
      content: "Content",
      post_type: @docs_type,
      status: "published",
      published_at: Time.current
    )

    blog_posts = Post.by_post_type("blog")
    assert_includes blog_posts, blog_post
    refute_includes blog_posts, docs_post
  end

  test "default ordering shows most recent posts first" do
    old_post = Post.create!(
      title: "Old Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 2.days.ago
    )

    new_post = Post.create!(
      title: "New Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    posts = Post.published.to_a
    assert_equal new_post, posts.first
    assert_equal old_post, posts.last
  end

  # Slug Generation Tests
  test "auto-generates slug from title when slug is not provided" do
    post = Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "hello-world", post.slug
  end

  test "slug is URL-safe" do
    post = Post.create!(
      title: "Hello World! This is a Test?",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "hello-world-this-is-a-test", post.slug
  end

  test "slugs are unique within their post_type" do
    Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    duplicate_post = Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    assert_not_equal "hello-world", duplicate_post.slug
    assert_match(/hello-world-\w+/, duplicate_post.slug)
  end

  test "same slug can exist in different post types" do
    blog_post = Post.create!(
      title: "Getting Started",
      content: "Content",
      post_type: @blog_type
    )

    docs_post = Post.create!(
      title: "Getting Started",
      content: "Content",
      post_type: @docs_type
    )

    assert_equal "getting-started", blog_post.slug
    assert_equal "getting-started", docs_post.slug
  end

  test "custom slug is not overwritten" do
    post = Post.create!(
      title: "Hello World",
      slug: "custom-slug",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "custom-slug", post.slug

    post.update!(title: "New Title")
    assert_equal "custom-slug", post.slug
  end

  test "#to_param returns slug" do
    post = Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal post.slug, post.to_param
  end

  # Publishing Workflow Tests
  test "new post defaults to draft status" do
    post = Post.create!(
      title: "New Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "draft", post.status
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

  # Reading Metrics Tests
  test "#reading_time returns estimated reading time in minutes when word_count is present" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type,
      word_count: 250
    )

    assert_equal 1, post.reading_time
  end

  test "#reading_time calculation uses configurable words per minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type,
      word_count: 500
    )

    # Default is 250 wpm: 500 / 250 = 2.0
    assert_equal 2, post.reading_time
  end

  test "#reading_time returns nil when word_count is not present" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )

    assert_nil post.reading_time
  end

  test "#reading_time rounds up to nearest minute" do
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type,
      word_count: 300
    )

    # 300 words / 250 wpm = 1.2 minutes, should round to 2
    assert_equal 2, post.reading_time
  end
end
