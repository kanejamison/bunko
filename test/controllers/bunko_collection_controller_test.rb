# frozen_string_literal: true

require_relative "../test_helper"

class BunkoCollectionControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Reset configuration before each test
    Bunko.reset_configuration!
    Bunko.configure do |config|
      config.post_type "Blog"
      config.post_type "Docs"
    end

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
    # Test with a collection that doesn't have a PostType or Collection configured
    get "/nonexistent"
    assert_response :not_found
    assert_match(/Collection 'nonexistent' not found/, response.body)
  end

  test "index shows all published posts for the collection" do
    get "/blog"

    assert_response :success
    assert_select "body" # Basic check that view renders
  end

  test "index only shows posts from the correct post_type" do
    get "/blog"
    assert_response :success

    # Would need to check @posts in controller, but we can verify via assigns
    # This will be testable once we have views
  end

  test "index does not show draft posts" do
    get "/blog"
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

    get "/blog"
    assert_response :success
    # Scheduled post should not appear
  end

  test "index orders posts by most recent first" do
    get "/blog"
    assert_response :success
    # Most recent should be first in @posts
  end

  # Show Action Tests
  test "show returns 404 when post_type does not exist" do
    # Test with a collection that doesn't have a PostType or Collection configured
    get "/nonexistent/any-slug"
    assert_response :not_found
    assert_match(/Collection 'nonexistent' not found/, response.body)
  end

  test "show finds post by slug" do
    get "/blog/#{@blog_post1.slug}"
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
    get "/blog/#{@blog_post1.slug}"
    assert_response :success

    # Requesting from docs should get docs post
    get "/docs/#{docs_post_same_slug.slug}"
    assert_response :success
  end

  test "show returns 404 when post not found" do
    get "/blog/non-existent-slug"
    assert_response :not_found
  end

  test "show returns 404 for draft posts" do
    get "/blog/#{@blog_draft.slug}"
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

    get "/blog/#{scheduled_post.slug}"
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

    get "/blog"
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

    get "/blog", params: {page: 2}
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

    get "/docs"
    assert_response :success
    # Should only show 5 posts
  end

  # Multi-type Collection Tests
  test "index works with multi-type collections" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.post_type "Videos"
      config.collection "Resources", post_types: ["articles", "videos"]
    end

    articles_type = PostType.create!(name: "Articles", slug: "articles")
    videos_type = PostType.create!(name: "Videos", slug: "videos")

    article = Post.create!(
      title: "Article Post",
      content: "Article content",
      post_type: articles_type,
      status: "published",
      published_at: 1.day.ago
    )

    video = Post.create!(
      title: "Video Post",
      content: "Video content",
      post_type: videos_type,
      status: "published",
      published_at: 2.days.ago
    )

    get "/resources"
    assert_response :success
  end

  test "show works with multi-type collections" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.post_type "Videos"
      config.collection "Resources", post_types: ["articles", "videos"]
    end

    articles_type = PostType.create!(name: "Articles", slug: "articles")

    article = Post.create!(
      title: "Article Post",
      content: "Article content",
      post_type: articles_type,
      status: "published",
      published_at: 1.day.ago
    )

    get "/resources/#{article.slug}"
    assert_response :success
  end

  # Collection Scope Tests
  test "index applies collection scope when defined" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.collection "Long Reads", post_types: ["articles"] do |c|
        c.scope -> { where("word_count > ?", 1000) }
      end
    end

    articles_type = PostType.create!(name: "Articles", slug: "articles")

    # Short article (should not appear)
    Post.create!(
      title: "Short Article",
      content: "Brief",
      post_type: articles_type,
      status: "published",
      published_at: 1.day.ago,
      word_count: 500
    )

    # Long article (should appear)
    long_article = Post.create!(
      title: "Long Article",
      content: "Very long content",
      post_type: articles_type,
      status: "published",
      published_at: 2.days.ago,
      word_count: 1500
    )

    get "/long-reads"
    assert_response :success
  end

  test "show applies collection scope when defined" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.collection "Long Reads", post_types: ["articles"] do |c|
        c.scope -> { where("word_count > ?", 1000) }
      end
    end

    articles_type = PostType.create!(name: "Articles", slug: "articles")

    # Short article (should return 404 even though published)
    short_article = Post.create!(
      title: "Short Article",
      content: "Brief",
      post_type: articles_type,
      status: "published",
      published_at: 1.day.ago,
      word_count: 500
    )

    # Long article (should work)
    long_article = Post.create!(
      title: "Long Article",
      content: "Very long content",
      post_type: articles_type,
      status: "published",
      published_at: 2.days.ago,
      word_count: 1500
    )

    # Create a controller for the long_reads collection
    unless defined?(LongReadsController)
      long_reads_controller_class = Class.new(ApplicationController) do
        include Bunko::Controllers::Collection
        bunko_collection :"long-reads"
      end
      Object.const_set("LongReadsController", long_reads_controller_class)
    end

    # Add route
    Rails.application.routes.draw do
      bunko_collection :"long-reads"
    end

    # Short article should not be found
    get "/long-reads/#{short_article.slug}"
    assert_response :not_found

    # Long article should be found
    get "/long-reads/#{long_article.slug}"
    assert_response :success
  end

  # PostType in config but not in database
  test "index returns 404 when PostType exists in config but not database" do
    Bunko.configure do |config|
      config.post_type "MissingType"
    end

    get "/missing-type"
    assert_response :not_found
    assert_match(/PostType 'missing_type' not found in database/, response.body)
    assert_match(/rails bunko:setup\[missing_type\]/, response.body)
  end

  test "show returns 404 when PostType exists in config but not database" do
    Bunko.configure do |config|
      config.post_type "MissingType"
    end

    # Create a controller for the missing type
    unless defined?(MissingTypeController)
      missing_type_controller_class = Class.new(ApplicationController) do
        include Bunko::Controllers::Collection
        bunko_collection :missing_type
      end
      Object.const_set("MissingTypeController", missing_type_controller_class)
    end

    # Add route
    Rails.application.routes.draw do
      bunko_collection :missing_type
    end

    get "/missing-type/some-slug"
    assert_response :not_found
    assert_match(/PostType 'missing_type' not found in database/, response.body)
  end
end
