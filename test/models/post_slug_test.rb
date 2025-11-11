# frozen_string_literal: true

require_relative "../test_helper"

class PostSlugTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "blog", title: "Blog")
    @docs_type = PostType.create!(name: "docs", title: "Docs")
  end

  test "auto-generates slug from title when slug is not provided" do
    post = Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "hello-world", post.slug
  end

  test "slug is URL-safe and parameterized" do
    post = Post.create!(
      title: "Hello World! This is a Test?",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "hello-world-this-is-a-test", post.slug
  end

  test "slug handles special characters" do
    post = Post.create!(
      title: "Hello & Goodbye!",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "hello-goodbye", post.slug
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
  end

  test "custom slug persists after title update" do
    post = Post.create!(
      title: "Hello World",
      slug: "custom-slug",
      content: "Content",
      post_type: @blog_type
    )

    post.update!(title: "New Title")
    assert_equal "custom-slug", post.slug
  end

  test "slug generation skips when title is blank" do
    post = Post.new(post_type: @blog_type)
    post.send(:generate_slug)

    assert_nil post.slug
  end

  test "slug generation adds random suffix when duplicate exists" do
    Post.create!(
      title: "Test Post",
      slug: "test-post",
      post_type: @blog_type,
      status: "draft"
    )

    post = Post.new(title: "Test Post", post_type: @blog_type)
    post.send(:generate_slug)

    assert_match(/^test-post-[a-f0-9]{8}$/, post.slug)
    refute_equal "test-post", post.slug
  end

  test "slug handles extreme special characters and punctuation" do
    post = Post.create!(
      title: "Great Post     Title (I'd Say No Way) ~!@\#$%^&*()_[]{\\}|;':\",./<>?`",
      content: "Content",
      post_type: @blog_type
    )

    # Rails parameterize splits contractions on apostrophes: "I'd" becomes "i-d"
    assert_equal "great-post-title-i-d-say-no-way", post.slug
  end
end
