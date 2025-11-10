# frozen_string_literal: true

require_relative "../test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  setup do
    # Reset configuration before each test
    Bunko.reset_configuration!
    Bunko.configure do |config|
      config.post_type "blog"
    end

    @blog_type = PostType.create!(name: "blog", title: "Blog")

    # Create 25 published posts for pagination testing
    # Post 1 is most recent, Post 25 is oldest (matches published_at DESC ordering)
    @posts = 25.times.map do |i|
      Post.create!(
        title: "Post #{i + 1}",
        content: "Content for post #{i + 1}",
        post_type: @blog_type,
        status: "published",
        published_at: i.days.ago # Post 1 is most recent (0 days ago)
      )
    end
  end

  # Pagination Metadata Structure Tests

  test "pagination metadata includes all required keys" do
    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_not_nil pagination

    # Test that all expected keys are present
    assert pagination.key?(:current_page), "Missing :current_page key"
    assert pagination.key?(:per_page), "Missing :per_page key"
    assert pagination.key?(:total_count), "Missing :total_count key"
    assert pagination.key?(:total_pages), "Missing :total_pages key"
    assert pagination.key?(:prev_page), "Missing :prev_page key"
    assert pagination.key?(:next_page), "Missing :next_page key"
  end

  test "pagination uses :current_page not :page as key" do
    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    # Should use :current_page
    assert pagination.key?(:current_page), "Should use :current_page key"
    assert_equal 1, pagination[:current_page]

    # Should NOT use :page
    assert_not pagination.key?(:page), "Should not use :page key (use :current_page instead)"
  end

  # First Page Tests

  test "first page has correct metadata" do
    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    assert_equal 1, pagination[:current_page]
    assert_equal 10, pagination[:per_page]
    assert_equal 25, pagination[:total_count]
    assert_equal 3, pagination[:total_pages]
    assert_nil pagination[:prev_page], "First page should have no prev_page"
    assert_equal 2, pagination[:next_page]
  end

  test "first page shows correct posts" do
    get "/blog"
    assert_response :success

    posts = controller.instance_variable_get(:@posts)
    assert_equal 10, posts.count, "First page should show 10 posts (default per_page)"

    # First post should be the most recent (Post 1)
    assert_equal "Post 1", posts.first.title
    # Last post on first page should be Post 10
    assert_equal "Post 10", posts.last.title
  end

  # Middle Page Tests

  test "middle page has correct metadata" do
    get "/blog", params: {page: 2}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    assert_equal 2, pagination[:current_page]
    assert_equal 10, pagination[:per_page]
    assert_equal 25, pagination[:total_count]
    assert_equal 3, pagination[:total_pages]
    assert_equal 1, pagination[:prev_page]
    assert_equal 3, pagination[:next_page]
  end

  test "middle page shows correct posts" do
    get "/blog", params: {page: 2}
    assert_response :success

    posts = controller.instance_variable_get(:@posts)
    assert_equal 10, posts.count, "Second page should show 10 posts"

    # First post on page 2 should be Post 11
    assert_equal "Post 11", posts.first.title
    # Last post on page 2 should be Post 20
    assert_equal "Post 20", posts.last.title
  end

  # Last Page Tests

  test "last page has correct metadata" do
    get "/blog", params: {page: 3}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    assert_equal 3, pagination[:current_page]
    assert_equal 10, pagination[:per_page]
    assert_equal 25, pagination[:total_count]
    assert_equal 3, pagination[:total_pages]
    assert_equal 2, pagination[:prev_page]
    assert_nil pagination[:next_page], "Last page should have no next_page"
  end

  test "last page shows remaining posts" do
    get "/blog", params: {page: 3}
    assert_response :success

    posts = controller.instance_variable_get(:@posts)
    assert_equal 5, posts.count, "Last page should show 5 remaining posts (25 % 10)"

    # First post on page 3 should be Post 21
    assert_equal "Post 21", posts.first.title
    # Last post on page 3 should be Post 25
    assert_equal "Post 25", posts.last.title
  end

  # Edge Cases

  test "page 0 is treated as page 1" do
    get "/blog", params: {page: 0}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 1, pagination[:current_page], "Page 0 should be normalized to page 1"
  end

  test "negative page is treated as page 1" do
    get "/blog", params: {page: -5}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 1, pagination[:current_page], "Negative page should be normalized to page 1"
  end

  test "page beyond last page shows empty results" do
    get "/blog", params: {page: 99}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    posts = controller.instance_variable_get(:@posts)

    assert_equal 99, pagination[:current_page]
    assert_equal 0, posts.count, "Page beyond last should show no posts"
    assert_nil pagination[:next_page], "Page beyond last should have no next_page"
  end

  # Total Pages Calculation Tests

  test "total_pages calculation with exact multiple" do
    # We have 25 posts, per_page = 10, so 3 pages
    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 3, pagination[:total_pages]
  end

  test "total_pages calculation with exact division" do
    # Create exactly 20 posts (2 pages with per_page = 10)
    Post.where(post_type: @blog_type).destroy_all

    20.times do |i|
      Post.create!(
        title: "Post #{i + 1}",
        content: "Content",
        post_type: @blog_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 20, pagination[:total_count]
    assert_equal 2, pagination[:total_pages]
  end

  test "total_pages calculation with single post" do
    Post.where(post_type: @blog_type).destroy_all

    Post.create!(
      title: "Only Post",
      content: "Content",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago
    )

    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 1, pagination[:total_count]
    assert_equal 1, pagination[:total_pages]
    assert_nil pagination[:prev_page]
    assert_nil pagination[:next_page]
  end

  test "total_pages calculation with no posts" do
    Post.where(post_type: @blog_type).destroy_all

    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    assert_equal 0, pagination[:total_count]
    assert_equal 0, pagination[:total_pages]
    assert_nil pagination[:prev_page]
    assert_nil pagination[:next_page]
  end

  # Custom per_page Tests

  test "respects custom per_page setting" do
    # Create a controller with custom per_page
    Bunko.reset_configuration!
    Bunko.configure do |config|
      config.post_type "docs"
    end

    docs_type = PostType.create!(name: "docs", title: "Docs")

    # Create 15 docs posts
    15.times do |i|
      Post.create!(
        title: "Doc #{i + 1}",
        content: "Content",
        post_type: docs_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    get "/docs"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)
    posts = controller.instance_variable_get(:@posts)

    # Docs controller has per_page: 5
    assert_equal 5, pagination[:per_page]
    assert_equal 5, posts.count
    assert_equal 15, pagination[:total_count]
    assert_equal 3, pagination[:total_pages]
  end

  # Integration Tests - Verifying view compatibility

  test "pagination metadata keys work with view templates" do
    get "/blog"
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    # These are the keys used in the view template
    # Verify they all work without causing NoMethodError
    assert_nothing_raised do
      pagination[:current_page] - 1 if pagination[:prev_page]
      pagination[:current_page] + 1 if pagination[:next_page]
      "Page #{pagination[:current_page]} of #{pagination[:total_pages]}"
    end
  end

  test "pagination prev_page and next_page values are correct for navigation" do
    get "/blog", params: {page: 2}
    assert_response :success

    pagination = controller.instance_variable_get(:@pagination)

    # If prev_page exists, current_page - 1 should equal prev_page
    if pagination[:prev_page]
      assert_equal pagination[:prev_page], pagination[:current_page] - 1
    end

    # If next_page exists, current_page + 1 should equal next_page
    if pagination[:next_page]
      assert_equal pagination[:next_page], pagination[:current_page] + 1
    end
  end
end
