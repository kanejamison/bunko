# frozen_string_literal: true

require_relative "../test_helper"

class CollectionConcernTest < ActiveSupport::TestCase
  class TestController < ApplicationController
    bunko_collection :blog, per_page: 5, order: :created_at_desc

    # Make private methods accessible for testing
    public :apply_ordering, :paginate, :pagination_metadata, :post_model
  end

  def setup
    @controller = TestController.new
    @blog_type = PostType.create!(name: "Blog", slug: "blog")

    # Create test posts with different timestamps
    @post1 = Post.create!(
      title: "Post 1",
      content: "Content 1",
      post_type: @blog_type,
      status: "published",
      published_at: 3.days.ago,
      created_at: 3.days.ago
    )

    @post2 = Post.create!(
      title: "Post 2",
      content: "Content 2",
      post_type: @blog_type,
      status: "published",
      published_at: 2.days.ago,
      created_at: 2.days.ago
    )

    @post3 = Post.create!(
      title: "Post 3",
      content: "Content 3",
      post_type: @blog_type,
      status: "published",
      published_at: 1.day.ago,
      created_at: 1.day.ago
    )
  end

  test "bunko_collection sets collection name" do
    assert_equal "blog", TestController.bunko_collection_name
  end

  test "bunko_collection sets options with defaults" do
    options = TestController.bunko_collection_options
    assert_equal 5, options[:per_page]
    assert_equal :created_at_desc, options[:order]
  end

  test "apply_ordering with published_at_desc" do
    @controller.instance_variable_set(:@bunko_collection_options, {order: :published_at_desc})
    query = Post.all
    ordered = @controller.apply_ordering(query)

    assert_equal @post3.id, ordered.first.id
    assert_equal @post1.id, ordered.last.id
  end

  test "apply_ordering with published_at_asc" do
    @controller.instance_variable_set(:@bunko_collection_options, {order: :published_at_asc})
    query = Post.unscoped.all
    ordered = @controller.apply_ordering(query)

    assert_equal @post1.id, ordered.first.id
    assert_equal @post3.id, ordered.last.id
  end

  test "apply_ordering with created_at_desc" do
    @controller.instance_variable_set(:@bunko_collection_options, {order: :created_at_desc})
    query = Post.all
    ordered = @controller.apply_ordering(query)

    assert_equal @post3.id, ordered.first.id
    assert_equal @post1.id, ordered.last.id
  end

  test "apply_ordering with created_at_asc" do
    @controller.instance_variable_set(:@bunko_collection_options, {order: :created_at_asc})
    query = Post.unscoped.all
    ordered = @controller.apply_ordering(query)

    assert_equal @post1.id, ordered.first.id
    assert_equal @post3.id, ordered.last.id
  end

  test "apply_ordering with unknown order returns query unchanged" do
    @controller.instance_variable_set(:@bunko_collection_options, {order: :invalid})
    query = Post.all
    ordered = @controller.apply_ordering(query)

    assert_equal query.to_sql, ordered.to_sql
  end

  test "paginate returns correct number of records per page" do
    @controller.instance_variable_set(:@bunko_collection_options, {per_page: 2})
    @controller.params = {page: 1}

    query = Post.published
    paginated = @controller.paginate(query)

    assert_equal 2, paginated.count
  end

  test "paginate handles page parameter" do
    # Create more posts for pagination
    7.times do |i|
      Post.create!(
        title: "Extra Post #{i}",
        content: "Content",
        post_type: @blog_type,
        status: "published",
        published_at: i.days.ago
      )
    end

    @controller.instance_variable_set(:@bunko_collection_options, {per_page: 5})
    @controller.params = {page: 2}

    query = Post.published
    paginated = @controller.paginate(query)

    assert_equal 5, paginated.count
    assert_equal 10, @controller.instance_variable_get(:@_total_count)
    assert_equal 2, @controller.instance_variable_get(:@_current_page)
  end

  test "paginate defaults to page 1 when page param is 0" do
    @controller.instance_variable_set(:@bunko_collection_options, {per_page: 10})
    @controller.params = {page: 0}

    query = Post.published
    @controller.paginate(query)

    assert_equal 1, @controller.instance_variable_get(:@_current_page)
  end

  test "pagination_metadata returns correct hash structure" do
    @controller.instance_variable_set(:@_current_page, 2)
    @controller.instance_variable_set(:@_per_page, 5)
    @controller.instance_variable_set(:@_total_count, 23)

    metadata = @controller.pagination_metadata

    assert_equal 2, metadata[:current_page]
    assert_equal 5, metadata[:per_page]
    assert_equal 23, metadata[:total_count]
    assert_equal 5, metadata[:total_pages]
    assert_equal 1, metadata[:prev_page]
    assert_equal 3, metadata[:next_page]
  end

  test "pagination_metadata prev_page is nil on first page" do
    @controller.instance_variable_set(:@_current_page, 1)
    @controller.instance_variable_set(:@_per_page, 10)
    @controller.instance_variable_set(:@_total_count, 50)

    metadata = @controller.pagination_metadata

    assert_nil metadata[:prev_page]
    assert_equal 2, metadata[:next_page]
  end

  test "pagination_metadata next_page is nil on last page" do
    @controller.instance_variable_set(:@_current_page, 5)
    @controller.instance_variable_set(:@_per_page, 10)
    @controller.instance_variable_set(:@_total_count, 50)

    metadata = @controller.pagination_metadata

    assert_equal 4, metadata[:prev_page]
    assert_nil metadata[:next_page]
  end

  test "post_model returns Post by default" do
    assert_equal Post, @controller.post_model
  end
end
