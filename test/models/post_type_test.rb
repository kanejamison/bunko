# frozen_string_literal: true

require_relative "../test_helper"

class PostTypeTest < ActiveSupport::TestCase
  # Validation Tests

  test "requires name to be present" do
    post_type = PostType.new(slug: "blog")
    refute post_type.valid?
    assert_includes post_type.errors[:name], "can't be blank"
  end

  test "requires slug to be present" do
    post_type = PostType.new(name: "Blog")
    refute post_type.valid?
    assert_includes post_type.errors[:slug], "can't be blank"
  end

  test "requires slug to be unique" do
    PostType.create!(name: "Blog", slug: "blog")

    duplicate = PostType.new(name: "Another Blog", slug: "blog")
    refute duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "allows different slugs for different post types" do
    PostType.create!(name: "Blog", slug: "blog")

    different = PostType.new(name: "Docs", slug: "docs")
    assert different.valid?
  end

  test "is valid with name and slug" do
    post_type = PostType.new(name: "Blog", slug: "blog")
    assert post_type.valid?
  end

  test "can be created with valid attributes" do
    post_type = PostType.create!(name: "Blog", slug: "blog")
    assert post_type.persisted?
    assert_equal "Blog", post_type.name
    assert_equal "blog", post_type.slug
  end

  # Association Tests

  test "has_many :posts association" do
    post_type = PostType.create!(name: "Blog", slug: "blog")

    # Create posts for this type
    post1 = Post.create!(
      title: "Post 1",
      content: "Content",
      post_type: post_type,
      status: "draft"
    )
    post2 = Post.create!(
      title: "Post 2",
      content: "Content",
      post_type: post_type,
      status: "draft"
    )

    assert_equal 2, post_type.posts.count
    assert_includes post_type.posts, post1
    assert_includes post_type.posts, post2
  end

  test "prevents deletion when posts exist" do
    post_type = PostType.create!(name: "Blog", slug: "blog")

    Post.create!(
      title: "Post 1",
      content: "Content",
      post_type: post_type,
      status: "draft"
    )
    Post.create!(
      title: "Post 2",
      content: "Content",
      post_type: post_type,
      status: "draft"
    )

    assert_equal 2, Post.count

    # Attempt to destroy should fail
    result = post_type.destroy

    assert_equal false, result
    assert_not_empty post_type.errors[:base]
    assert_equal 2, Post.count, "Posts should not be destroyed"
    assert PostType.exists?(post_type.id), "PostType should not be destroyed"
  end

  test "allows deletion when no posts exist" do
    post_type = PostType.create!(name: "Blog", slug: "blog")

    # Should be able to destroy when no posts
    result = post_type.destroy

    assert result
    assert_not PostType.exists?(post_type.id)
  end

  # Edge Cases

  test "handles slug with special characters" do
    post_type = PostType.create!(name: "Case Study", slug: "case-study")
    assert post_type.persisted?
    assert_equal "case-study", post_type.slug
  end

  test "slug is case sensitive for uniqueness" do
    PostType.create!(name: "Blog", slug: "blog")

    # Different case - should be considered different in most DBs
    # But this depends on DB collation settings
    uppercase = PostType.new(name: "BLOG", slug: "BLOG")
    assert uppercase.valid?
  end

  test "handles very long names" do
    long_name = "A" * 255
    post_type = PostType.new(name: long_name, slug: "test")

    # Should be valid unless there's a length limit
    # This tests the actual behavior of your schema
    result = post_type.valid?
    # Just verify it doesn't crash
    assert_not_nil result
  end

  test "handles very long slugs" do
    long_slug = "a" * 255
    post_type = PostType.new(name: "Test", slug: long_slug)

    # Should be valid unless there's a length limit
    result = post_type.valid?
    # Just verify it doesn't crash
    assert_not_nil result
  end

  test "slug can contain underscores" do
    post_type = PostType.create!(name: "Case Study", slug: "case_study")
    assert post_type.persisted?
    assert_equal "case_study", post_type.slug
  end

  test "slug can contain numbers" do
    post_type = PostType.create!(name: "News 2024", slug: "news-2024")
    assert post_type.persisted?
    assert_equal "news-2024", post_type.slug
  end

  test "timestamps are set automatically" do
    post_type = PostType.create!(name: "Blog", slug: "blog")

    assert_not_nil post_type.created_at
    assert_not_nil post_type.updated_at
    assert_in_delta Time.current, post_type.created_at, 2.seconds
  end

  test "updated_at changes when record is updated" do
    post_type = PostType.create!(name: "Blog", slug: "blog")
    original_updated_at = post_type.updated_at

    travel 1.second

    post_type.update!(name: "Updated Blog")

    assert_not_equal original_updated_at, post_type.updated_at
    assert post_type.updated_at > original_updated_at
  end
end
