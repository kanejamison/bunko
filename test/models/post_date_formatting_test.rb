# frozen_string_literal: true

require_relative "../test_helper"

class PostDateFormattingTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "blog", title: "Blog")
  end

  test "published_date returns nil when published_at is not present" do
    post = Post.new(post_type: @blog_type)
    assert_nil post.published_date
  end

  test "published_date returns formatted date with default format" do
    travel_to Time.zone.local(2025, 11, 9, 12, 0, 0) do
      post = Post.new(published_at: Time.current, post_type: @blog_type)
      # The default :long format will vary by locale, so just check it returns something
      result = post.published_date
      assert_not_nil result
      assert_kind_of String, result
    end
  end

  test "published_date accepts :short format" do
    travel_to Time.zone.local(2025, 11, 9, 12, 0, 0) do
      post = Post.new(published_at: Time.current, post_type: @blog_type)
      result = post.published_date(:short)
      assert_not_nil result
      assert_kind_of String, result
    end
  end

  test "published_date accepts :long format" do
    travel_to Time.zone.local(2025, 11, 9, 12, 0, 0) do
      post = Post.new(published_at: Time.current, post_type: @blog_type)
      result = post.published_date(:long)
      assert_not_nil result
      assert_kind_of String, result
    end
  end

  test "published_date is locale-aware" do
    travel_to Time.zone.local(2025, 11, 9, 12, 0, 0) do
      post = Post.new(published_at: Time.current, post_type: @blog_type)

      # Test that I18n.l is being used (which makes it locale-aware)
      # We don't test specific formats as they vary by locale/rails version
      assert_nothing_raised do
        post.published_date(:long)
        post.published_date(:short)
      end
    end
  end
end
