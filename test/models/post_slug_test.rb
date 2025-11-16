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

  test "to_param returns slug for URL generation" do
    post = Post.create!(
      title: "Hello World",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal post.slug, post.to_param
    assert_equal "hello-world", post.to_param
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

  # Format validation tests

  test "rejects slug with uppercase letters" do
    post = Post.new(
      title: "Test",
      slug: "Hello-World",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug with spaces" do
    post = Post.new(
      title: "Test",
      slug: "hello world",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug with special characters" do
    invalid_slugs = [
      "hello!world",
      "hello@world",
      "hello#world",
      "hello$world",
      "hello%world",
      "hello&world",
      "hello*world",
      "hello(world)",
      "hello[world]",
      "hello{world}",
      "hello/world",
      "hello\\world",
      "hello|world",
      "hello:world",
      "hello;world",
      "hello'world",
      'hello"world',
      "hello,world",
      "hello.world",
      "hello?world",
      "hello<world>",
      "hello~world",
      "hello`world",
      "hello=world",
      "hello+world"
    ]

    invalid_slugs.each do |invalid_slug|
      post = Post.new(
        title: "Test",
        slug: invalid_slug,
        post_type: @blog_type
      )

      assert_not post.valid?, "Expected '#{invalid_slug}' to be invalid"
      assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
    end
  end

  test "rejects slug with path traversal attempts" do
    path_traversal_attempts = [
      "../",
      "../../admin",
      "..%2F",
      "..%2Fadmin",
      "..",
      "../../../etc/passwd"
    ]

    path_traversal_attempts.each do |invalid_slug|
      post = Post.new(
        title: "Test",
        slug: invalid_slug,
        post_type: @blog_type
      )

      assert_not post.valid?, "Expected '#{invalid_slug}' to be invalid"
      assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
    end
  end

  test "rejects slug with leading hyphen" do
    post = Post.new(
      title: "Test",
      slug: "-hello-world",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug with trailing hyphen" do
    post = Post.new(
      title: "Test",
      slug: "hello-world-",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug with consecutive hyphens" do
    post = Post.new(
      title: "Test",
      slug: "hello--world",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug that is only hyphens" do
    post = Post.new(
      title: "Test",
      slug: "---",
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "must contain only lowercase letters, numbers, and hyphens"
  end

  test "rejects slug exceeding 255 characters" do
    long_slug = "a" * 256

    post = Post.new(
      title: "Test",
      slug: long_slug,
      post_type: @blog_type
    )

    assert_not post.valid?
    assert_includes post.errors[:slug], "is too long (maximum is 255 characters)"
  end

  test "accepts valid slug with lowercase letters" do
    post = Post.new(
      title: "Test",
      slug: "hello",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
  end

  test "accepts valid slug with lowercase letters and hyphens" do
    post = Post.new(
      title: "Test",
      slug: "hello-world",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
  end

  test "accepts valid slug with lowercase letters, numbers, and hyphens" do
    post = Post.new(
      title: "Test",
      slug: "hello-world-123",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
  end

  test "accepts valid slug with only numbers" do
    post = Post.new(
      title: "Test",
      slug: "12345",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
  end

  test "accepts valid slug with numbers and hyphens" do
    post = Post.new(
      title: "Test",
      slug: "123-456-789",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
  end

  test "accepts slug at maximum length (255 characters)" do
    # Create a valid slug exactly 255 characters long
    # Format: "a-b-c-..." to meet format requirements
    # 255 chars = 128 'a' chars + 127 '-' chars = 128 parts joined by '-'
    max_slug = Array.new(128, "a").join("-")

    post = Post.new(
      title: "Test",
      slug: max_slug,
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
    assert_equal 255, post.slug.length
  end

  test "auto-generated slugs pass format validation" do
    post = Post.create!(
      title: "Hello World 123!",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
    assert_equal "hello-world-123", post.slug
  end

  test "auto-generated slugs with random suffix pass format validation" do
    # Create first post
    Post.create!(
      title: "Test Post",
      slug: "test-post",
      post_type: @blog_type,
      status: "draft"
    )

    # Create duplicate - should get random suffix
    post = Post.create!(
      title: "Test Post",
      content: "Content",
      post_type: @blog_type
    )

    assert post.valid?
    assert_match(/^test-post-[a-f0-9]{8}$/, post.slug)
  end

  # Auto-generation safety tests - ensure problematic characters are never generated

  test "auto-generation converts spaces to hyphens" do
    post = Post.create!(
      title: "This Has Multiple Spaces",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "this-has-multiple-spaces", post.slug
    assert_no_match(/\s/, post.slug, "Slug should not contain spaces")
    assert_no_match(/%20/, post.slug, "Slug should not contain URL-encoded spaces")
  end

  test "auto-generation converts uppercase to lowercase" do
    post = Post.create!(
      title: "UPPERCASE Title",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "uppercase-title", post.slug
    assert_equal post.slug, post.slug.downcase, "Slug should be all lowercase"
  end

  test "auto-generation removes reserved URL characters" do
    reserved_chars = {
      "Title #1" => "title-1",
      "What? Really?" => "what-really",
      "Foo & Bar" => "foo-bar",
      "A=B" => "a-b",
      "A+B" => "a-b",
      "50%" => "50",
      "Path/To/File" => "path-to-file",
      "Back\\Slash" => "back-slash"
    }

    reserved_chars.each do |title, expected_slug|
      post = Post.create!(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      assert_equal expected_slug, post.slug, "Title '#{title}' should generate slug '#{expected_slug}'"
      assert_no_match(/[#?&=+%\/\\]/, post.slug, "Slug should not contain reserved characters")

      # Clean up for next iteration
      post.destroy
    end
  end

  test "auto-generation handles non-ASCII characters with Latin equivalents" do
    non_ascii_examples = {
      "Café" => "cafe",
      "Naïve" => "naive",
      "Über Cool" => "uber-cool",
      "Résumé" => "resume",
      "São Paulo" => "sao-paulo",
      "Zürich" => "zurich",
      "Français" => "francais",
      "Español" => "espanol"
    }

    non_ascii_examples.each do |title, expected_slug|
      post = Post.create!(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      assert_equal expected_slug, post.slug, "Title '#{title}' should generate slug '#{expected_slug}'"
      assert post.slug.ascii_only?, "Slug should contain only ASCII characters for '#{title}'"

      # Clean up for next iteration
      post.destroy
    end
  end

  test "auto-generation fails for titles with only non-Latin characters" do
    # Titles with only non-Latin characters that can't be transliterated
    non_latin_titles = ["日本語", "Москва", "中文", "العربية"]

    non_latin_titles.each do |title|
      post = Post.new(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      # Parameterize returns empty string, so slug won't be auto-generated
      # This will fail validation, requiring manual slug entry
      assert_not post.valid?, "Post with title '#{title}' should be invalid (slug can't be auto-generated)"
      assert_includes post.errors[:slug], "can't be blank"
    end
  end

  test "auto-generation removes special symbols" do
    symbols = {
      "Copyright © 2024" => "copyright-2024",
      "Registered ® Trademark" => "registered-trademark",
      "Euro € Symbol" => "euro-symbol",
      "At @ Symbol" => "at-symbol",
      "Dollar $ Sign" => "dollar-sign",
      "Asterisk * Star" => "asterisk-star",
      "Parentheses (test)" => "parentheses-test",
      "Brackets [test]" => "brackets-test",
      "Braces {test}" => "braces-test",
      "Pipe | Symbol" => "pipe-symbol",
      "Colon: Test" => "colon-test",
      "Semicolon; Test" => "semicolon-test",
      "Quote 'Test'" => "quote-test",
      'Double "Quote"' => "double-quote",
      "Less < Than" => "less-than",
      "Greater > Than" => "greater-than",
      "Comma, Test" => "comma-test",
      "Period. Test" => "period-test",
      "Tilde ~ Test" => "tilde-test",
      "Backtick ` Test" => "backtick-test"
    }

    symbols.each do |title, expected_slug|
      post = Post.create!(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      assert_equal expected_slug, post.slug, "Title '#{title}' should generate slug '#{expected_slug}'"
      assert_no_match(/[©®€@$*()\[\]{}|:;'"<>,.~`]/, post.slug, "Slug should not contain special symbols")

      # Clean up for next iteration
      post.destroy
    end
  end

  test "auto-generation handles underscores" do
    post = Post.create!(
      title: "snake_case_title",
      content: "Content",
      post_type: @blog_type
    )

    # Underscores should be converted to hyphens (Rails parameterize behavior)
    assert_equal "snake-case-title", post.slug
    assert_no_match(/_/, post.slug, "Slug should not contain underscores")
  end

  test "auto-generation handles multiple consecutive problematic characters" do
    post = Post.create!(
      title: "Multiple   Spaces    &&&   Symbols!!!",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "multiple-spaces-symbols", post.slug
    assert_no_match(/--/, post.slug, "Slug should not contain consecutive hyphens")
  end

  test "auto-generation handles mixed problematic characters" do
    post = Post.create!(
      title: "Mix€d Ch@r$: Tëst#1 (2024)",
      content: "Content",
      post_type: @blog_type
    )

    # Should only contain lowercase letters, numbers, and single hyphens
    assert_match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, post.slug)
    assert post.slug.ascii_only?
  end

  test "auto-generation handles leading and trailing problematic characters" do
    titles = [
      "   Leading Spaces",
      "Trailing Spaces   ",
      "___Underscores___",
      "!!!Exclamation!!!",
      "...Dots...",
      "---Hyphens---"
    ]

    titles.each do |title|
      post = Post.create!(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      # Slug should not start or end with hyphen
      assert_no_match(/\A-/, post.slug, "Slug should not start with hyphen for '#{title}'")
      assert_no_match(/-\z/, post.slug, "Slug should not end with hyphen for '#{title}'")

      # Clean up for next iteration
      post.destroy
    end
  end

  test "auto-generation creates valid slug from title with only special characters" do
    # Edge case: what if title has ONLY special characters?
    post = Post.new(
      title: "!@#$%^&*()",
      content: "Content",
      post_type: @blog_type
    )

    # This should generate an empty slug, which will fail validation
    # In real usage, this would require manual slug entry
    assert_not post.valid?
    assert_includes post.errors[:slug], "can't be blank"
  end

  test "auto-generation preserves numbers correctly" do
    post = Post.create!(
      title: "Ruby 3.2.0 Release",
      content: "Content",
      post_type: @blog_type
    )

    assert_equal "ruby-3-2-0-release", post.slug
    assert_match(/\d+/, post.slug, "Slug should preserve numbers")
  end

  test "auto-generated slug always passes format validation" do
    # Test a variety of real-world title examples
    real_world_titles = [
      "Getting Started with Rails",
      "10 Tips for Better Code",
      "Why You Should Use Ruby",
      "Understanding HTTP/2",
      "The Future of JavaScript (2024)",
      "API Design Best Practices",
      "Database Indexing: A Guide",
      "CSS Grid vs Flexbox",
      "Building RESTful APIs",
      "Test-Driven Development"
    ]

    real_world_titles.each do |title|
      post = Post.create!(
        title: title,
        content: "Content",
        post_type: @blog_type
      )

      assert post.valid?, "Post with title '#{title}' should be valid"
      assert_match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, post.slug, "Auto-generated slug should match format")
      assert post.slug.length <= 255, "Slug should not exceed maximum length"

      # Clean up for next iteration
      post.destroy
    end
  end
end
