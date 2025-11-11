# frozen_string_literal: true

require_relative "../test_helper"

class PostContentFormattingTest < ActiveSupport::TestCase
  setup do
    @blog_type = PostType.create!(name: "blog", title: "Blog")
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

  # Additional HTML stripping tests for improved sanitization

  test "excerpt strips nested HTML tags" do
    post = Post.new(
      content: "<div><p>Nested <span><strong>HTML</strong> tags</span> should be removed</p></div>",
      post_type: @blog_type
    )
    result = post.excerpt
    assert_equal "Nested HTML tags should be removed", result
    refute_includes result, "<div>"
    refute_includes result, "<span>"
  end

  test "excerpt preserves HTML entities as-is" do
    post = Post.new(
      content: "Hello&nbsp;world&amp;friends&lt;test&gt;",
      post_type: @blog_type
    )
    result = post.excerpt
    # Sanitizer leaves entities as-is (doesn't decode them)
    assert_equal "Hello&nbsp;world&amp;friends&lt;test&gt;", result
  end

  test "excerpt removes script tags but preserves content" do
    post = Post.new(
      content: "Clean text <script>alert('bad');</script> more text",
      post_type: @blog_type
    )
    result = post.excerpt
    # Tags are removed but content inside script tags remains
    # This is expected behavior of Rails sanitizer
    assert_equal "Clean text alert('bad'); more text", result
    refute_includes result, "<script>"
    refute_includes result, "</script>"
  end

  test "excerpt removes style tags but preserves content" do
    post = Post.new(
      content: "Visible text <style>.class { color: red; }</style> more visible",
      post_type: @blog_type
    )
    result = post.excerpt
    # Tags are removed but content inside style tags remains
    # This is expected behavior of Rails sanitizer
    assert_equal "Visible text .class { color: red; } more visible", result
    refute_includes result, "<style>"
    refute_includes result, "</style>"
  end

  test "excerpt collapses whitespace from removed tags" do
    post = Post.new(
      content: "<p>First paragraph</p>    <p>Second paragraph</p>",
      post_type: @blog_type
    )
    result = post.excerpt
    assert_equal "First paragraph Second paragraph", result
    # Should not have multiple spaces
    refute_match(/\s{2,}/, result)
  end

  test "excerpt handles self-closing tags" do
    post = Post.new(
      content: "Text with <br/> line break <img src='test.jpg'/> and image",
      post_type: @blog_type
    )
    result = post.excerpt
    assert_equal "Text with line break and image", result
    refute_includes result, "<br"
    refute_includes result, "<img"
  end

  test "excerpt handles complex real-world HTML" do
    post = Post.new(
      content: <<~HTML,
        <article>
          <h1>Title Here</h1>
          <p>This is a <strong>blog post</strong> with <em>various</em> formatting.</p>
          <ul>
            <li>Item one</li>
            <li>Item two</li>
          </ul>
          <p>Final paragraph with <a href="#">link</a>.</p>
        </article>
      HTML
      post_type: @blog_type
    )
    result = post.excerpt(length: 50)
    # Should extract clean text without any HTML
    assert_includes result, "Title Here"
    assert_includes result, "blog post"
    refute_includes result, "<h1>"
    refute_includes result, "<strong>"
    refute_includes result, "<ul>"
    refute_includes result, "<a"
  end

  test "excerpt strips HTML before calculating length" do
    # 50 characters of HTML that results in much shorter text
    post = Post.new(
      content: "<p><strong><em>Short</em></strong></p>",
      post_type: @blog_type
    )
    result = post.excerpt(length: 10)
    # Should return full text since "Short" is only 5 chars
    assert_equal "Short", result
    refute_match(/\.\.\.$/, result) # Should not be truncated
  end

  test "excerpt handles malformed HTML gracefully" do
    post = Post.new(
      content: "<p>Unclosed tag <strong>text without closing",
      post_type: @blog_type
    )
    result = post.excerpt
    assert_equal "Unclosed tag text without closing", result
    # Should still strip tags even if malformed
    refute_includes result, "<p>"
    refute_includes result, "<strong>"
  end
end
