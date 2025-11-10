# frozen_string_literal: true

require_relative "../test_helper"

class PostScopesTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
    @docs_type = PostType.create!(name: "Docs", slug: "docs")
  end

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

  test ".by_post_type filters posts by post type slug" do
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

    docs_posts = Post.by_post_type("docs")
    assert_includes docs_posts, docs_post
    refute_includes docs_posts, blog_post
  end

  test "default scope orders posts by created_at desc (most recent first)" do
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

    posts = Post.all.to_a
    assert_equal new_post, posts.first
    assert_equal old_post, posts.last
  end

  test ".published scope orders by published_at desc" do
    older_post = Post.create!(
      title: "Older Published Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 3.days.ago
    )

    newer_post = Post.create!(
      title: "Newer Published Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    published_posts = Post.published.to_a
    assert_equal newer_post, published_posts.first
    assert_equal older_post, published_posts.last
  end
end
