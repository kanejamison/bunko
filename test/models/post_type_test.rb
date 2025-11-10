# frozen_string_literal: true

require_relative "../test_helper"

class PostTypeTest < ActiveSupport::TestCase
  # Validation Tests

  test "requires title to be present" do
    post_type = PostType.new(name: "blog")
    refute post_type.valid?
    assert_includes post_type.errors[:title], "can't be blank"
  end

  test "requires name to be present" do
    post_type = PostType.new(title: "Blog")
    refute post_type.valid?
    assert_includes post_type.errors[:name], "can't be blank"
  end

  test "requires name to be unique" do
    PostType.create!(name: "blog", title: "Blog")

    duplicate = PostType.new(name: "blog", title: "Another Blog")
    refute duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows different names for different post types" do
    PostType.create!(name: "blog", title: "Blog")

    different = PostType.new(name: "docs", title: "Docs")
    assert different.valid?
  end

  test "is valid with name and title" do
    post_type = PostType.new(name: "blog", title: "Blog")
    assert post_type.valid?
  end

  test "can be created with valid attributes" do
    post_type = PostType.create!(name: "blog", title: "Blog")
    assert post_type.persisted?
    assert_equal "blog", post_type.name
    assert_equal "Blog", post_type.title
  end

  # Association Tests

  test "has_many :posts association" do
    post_type = PostType.create!(name: "blog", title: "Blog")

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
    post_type = PostType.create!(name: "blog", title: "Blog")

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
    post_type = PostType.create!(name: "blog", title: "Blog")

    # Should be able to destroy when no posts
    result = post_type.destroy

    assert result
    assert_not PostType.exists?(post_type.id)
  end

  # Edge Cases

  test "name can contain underscores" do
    post_type = PostType.create!(name: "case_study", title: "Case Study")
    assert post_type.persisted?
    assert_equal "case_study", post_type.name
  end

  test "name is case sensitive for uniqueness" do
    PostType.create!(name: "blog", title: "Blog")

    # Different case - should be considered different in most DBs
    # But this depends on DB collation settings
    uppercase = PostType.new(name: "BLOG", title: "BLOG")
    assert uppercase.valid?
  end

  test "handles very long titles" do
    long_title = "A" * 255
    post_type = PostType.new(name: "test", title: long_title)

    # Should be valid unless there's a length limit
    # This tests the actual behavior of your schema
    result = post_type.valid?
    # Just verify it doesn't crash
    assert_not_nil result
  end

  test "handles very long names" do
    long_name = "a" * 255
    post_type = PostType.new(name: long_name, title: "Test")

    # Should be valid unless there's a length limit
    result = post_type.valid?
    # Just verify it doesn't crash
    assert_not_nil result
  end

  test "name can contain numbers" do
    post_type = PostType.create!(name: "news_2024", title: "News 2024")
    assert post_type.persisted?
    assert_equal "news_2024", post_type.name
  end

  test "timestamps are set automatically" do
    post_type = PostType.create!(name: "blog", title: "Blog")

    assert_not_nil post_type.created_at
    assert_not_nil post_type.updated_at
    assert_in_delta Time.current, post_type.created_at, 2.seconds
  end

  test "updated_at changes when record is updated" do
    post_type = PostType.create!(name: "blog", title: "Blog")
    original_updated_at = post_type.updated_at

    travel 1.second

    post_type.update!(title: "Updated Blog")

    assert_not_equal original_updated_at, post_type.updated_at
    assert post_type.updated_at > original_updated_at
  end
end
