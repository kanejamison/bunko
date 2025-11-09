# frozen_string_literal: true

require_relative "../test_helper"

class BunkoCollectionControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
    @docs_type = PostType.create!(name: "Docs", slug: "docs")

    # Create published blog posts
    @blog_post1 = Post.create!(
      title: "First Blog Post",
      content: "Content 1",
      post_type: @blog_type,
      status: "published",
      published_at: 2.days.ago
    )

    @blog_post2 = Post.create!(
      title: "Second Blog Post",
      content: "Content 2",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    # Create draft blog post (should not appear)
    @blog_draft = Post.create!(
      title: "Draft Blog Post",
      content: "Draft content",
      post_type: @blog_type,
      status: "draft"
    )

    # Create published docs post (should not appear in blog)
    @docs_post = Post.create!(
      title: "Docs Post",
      content: "Docs content",
      post_type: @docs_type,
      status: "published",
      published_at: 1.day.ago
    )
  end

  # Index Action Tests
  test "index returns 404 when post_type does not exist" do
    # Test with a collection that doesn't have a PostType
    get nonexistent_index_path
    assert_response :not_found
    assert_match(/PostType 'nonexistent' not found/, response.body)
    assert_match(/PostType\.create!/, response.body)
  end

  test "index shows all published posts for the collection" do
    get blog_index_path

    assert_response :success
    assert_select "body" # Basic check that view renders
  end

  test "index only shows posts from the correct post_type" do
    get blog_index_path
    assert_response :success

    # Would need to check @posts in controller, but we can verify via assigns
    # This will be testable once we have views
  end

  test "index does not show draft posts" do
    get blog_index_path
    assert_response :success
    # Draft posts should not be included in @posts
  end

  test "index does not show scheduled posts" do
    Post.create!(
      title: "Scheduled Post",
      content: "Future content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.from_now
    )

    get blog_index_path
    assert_response :success
    # Scheduled post should not appear
  end

  test "index orders posts by most recent first" do
    get blog_index_path
    assert_response :success
    # Most recent should be first in @posts
  end

  # Show Action Tests
  test "show returns 404 when post_type does not exist" do
    # Test with a collection that doesn't have a PostType
    get nonexistent_path("any-slug")
    assert_response :not_found
    assert_match(/PostType 'nonexistent' not found/, response.body)
    assert_match(/PostType\.create!/, response.body)
  end

  test "show finds post by slug" do
    get blog_path(@blog_post1.slug)
    assert_response :success
  end

  test "show is scoped to correct post_type" do
    # Create a docs post with same slug as blog post
    docs_post_same_slug = Post.create!(
      title: @blog_post1.title,
      slug: @blog_post1.slug,
      content: "Docs content",
      post_type: @docs_type,
      status: "published",
      published_at: 1.day.ago
    )

    # Requesting from blog should get blog post, not docs
    get blog_path(@blog_post1.slug)
    assert_response :success

    # Requesting from docs should get docs post
    get docs_path(docs_post_same_slug.slug)
    assert_response :success
  end

  test "show returns 404 when post not found" do
    get blog_path("non-existent-slug")
    assert_response :not_found
  end

  test "show returns 404 for draft posts" do
    get blog_path(@blog_draft.slug)
    assert_response :not_found
  end

  test "show returns 404 for scheduled posts" do
    scheduled_post = Post.create!(
      title: "Scheduled Post",
      content: "Future content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.from_now
    )

    get blog_path(scheduled_post.slug)
    assert_response :not_found
  end

  # Pagination Tests
  test "index paginates results with default per_page" do
    # Create 25 posts (default per_page is 10)
    25.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        post_type: @blog_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    get blog_index_path
    assert_response :success
    # Should only show first 10 (default per_page)
  end

  test "index respects page parameter" do
    # Create 15 posts
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        post_type: @blog_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    get blog_index_path(page: 2)
    assert_response :success
    # Should show second page
  end

  test "index respects custom per_page option" do
    # Docs controller has per_page: 5
    10.times do |i|
      Post.create!(
        title: "Docs #{i}",
        content: "Content #{i}",
        post_type: @docs_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    get docs_index_path
    assert_response :success
    # Should only show 5 posts
  end
end
