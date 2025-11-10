# frozen_string_literal: true

require_relative "../test_helper"

class PostMetaTagsTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
  end

  test "meta_description_tag returns nil when meta_description field does not exist" do
    post = Post.new(post_type: @blog_type)
    assert_nil post.meta_description_tag
  end

  test "meta_description_tag returns nil when meta_description is blank" do
    # Skip if Post doesn't have meta_description column
    skip unless Post.column_names.include?("meta_description")

    post = Post.new(post_type: @blog_type, meta_description: nil)
    assert_nil post.meta_description_tag
  end

  test "meta_description_tag returns meta tag when meta_description is present" do
    # Skip if Post doesn't have meta_description column
    skip unless Post.column_names.include?("meta_description")

    post = Post.new(
      post_type: @blog_type,
      meta_description: "This is a test description"
    )
    result = post.meta_description_tag

    assert_includes result, '<meta name="description"'
    assert_includes result, 'content="This is a test description"'
  end

  test "meta_description_tag escapes HTML in description" do
    # Skip if Post doesn't have meta_description column
    skip unless Post.column_names.include?("meta_description")

    post = Post.new(
      post_type: @blog_type,
      meta_description: 'Test with "quotes" and <html>'
    )
    result = post.meta_description_tag

    # Should escape special characters
    assert_includes result, "&quot;"
    assert_includes result, "&lt;"
    assert_includes result, "&gt;"
  end

  test "meta_description_tag returns HTML-safe string" do
    # Skip if Post doesn't have meta_description column
    skip unless Post.column_names.include?("meta_description")

    post = Post.new(
      post_type: @blog_type,
      meta_description: "Test description"
    )
    result = post.meta_description_tag

    assert result.html_safe?
  end
end
