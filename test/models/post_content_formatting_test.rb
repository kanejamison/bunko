# frozen_string_literal: true

require_relative "../test_helper"

class PostContentFormattingTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "Blog", slug: "blog")
  end

  test "excerpt returns nil when content is not present" do
    post = Post.new(post_type: @blog_type)
    assert_nil post.excerpt
  end

  test "excerpt returns full text when shorter than length" do
    post = Post.new(content: "Short content", post_type: @blog_type)
    assert_equal "Short content", post.excerpt(length: 100)
  end

  test "excerpt truncates to word boundary" do
    post = Post.new(
      content: "This is a long piece of content that should be truncated at a word boundary",
      post_type: @blog_type
    )
    result = post.excerpt(length: 30)
    assert_equal "This is a long piece of...", result
    refute_match(/truncat/, result) # Should not include partial word
  end

  test "excerpt strips HTML tags" do
    post = Post.new(
      content: "<p>This is <strong>HTML</strong> content</p>",
      post_type: @blog_type
    )
    result = post.excerpt
    assert_equal "This is HTML content", result
    refute_includes result, "<p>"
    refute_includes result, "<strong>"
  end

  test "excerpt uses custom omission" do
    post = Post.new(
      content: "This is a long piece of content that should be truncated",
      post_type: @blog_type
    )
    result = post.excerpt(length: 20, omission: "…")
    assert_match(/…$/, result)
    refute_match(/\.\.\.$/, result)
  end

  test "excerpt with default length of 160 characters" do
    long_content = "Lorem ipsum dolor sit amet, " * 20 # Very long content
    post = Post.new(content: long_content, post_type: @blog_type)

    result = post.excerpt
    assert result.length <= 163 # 160 + "..." (3 chars)
  end

  test "excerpt preserves word boundaries with complex content" do
    post = Post.new(
      content: "The quick brown fox jumps over the lazy dog again and again",
      post_type: @blog_type
    )
    result = post.excerpt(length: 25)

    # Should break at word boundary, not mid-word
    assert_equal "The quick brown fox...", result
  end

  test "excerpt uses configured default length when not specified" do
    # Change config temporarily
    original_length = Bunko.configuration.excerpt_length
    Bunko.configuration.excerpt_length = 50

    long_content = "This is a long piece of content that should be truncated at the configured default length"
    post = Post.new(content: long_content, post_type: @blog_type)

    result = post.excerpt
    assert result.length <= 53 # 50 + "..." (3 chars)
    assert_equal "This is a long piece of content that should be...", result

    # Restore original
    Bunko.configuration.excerpt_length = original_length
  end
end
