# frozen_string_literal: true

require_relative "../test_helper"
require "rake"

class BunkoSampleDataTaskTest < Minitest::Test
  def setup
    # Clean database before each test
    Post.delete_all
    PostType.delete_all

    # Create test PostTypes
    @blog_type = PostType.create!(name: "blog", title: "Blog")
    @docs_type = PostType.create!(name: "docs", title: "Documentation")
    @changelog_type = PostType.create!(name: "changelog", title: "Changelog")

    # Load Rails rake tasks and our bunko tasks
    Dummy::Application.load_tasks if Rake::Task.tasks.empty?

    # Mock $stdin to prevent production warning from blocking tests
    @original_stdin = $stdin
    $stdin = StringIO.new("\n") # Simulates pressing Enter
  end

  def teardown
    # Restore $stdin
    $stdin = @original_stdin

    # Clean up database
    Post.delete_all
    PostType.delete_all
  end

  def test_sample_data_creates_posts_for_all_post_types
    ENV["COUNT"] = "5"

    run_rake_task("bunko:sample_data")

    assert_equal 15, Post.count # 5 posts × 3 post types
    assert_equal 5, Post.where(post_type: @blog_type).count
    assert_equal 5, Post.where(post_type: @docs_type).count
    assert_equal 5, Post.where(post_type: @changelog_type).count
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_respects_count_parameter
    ENV["COUNT"] = "3"

    run_rake_task("bunko:sample_data")

    assert_equal 9, Post.count # 3 posts × 3 post types
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_uses_default_count
    # Don't set COUNT, should default to 100
    run_rake_task("bunko:sample_data")

    assert_equal 300, Post.count # 100 posts × 3 post types
  end

  def test_sample_data_clears_existing_when_requested
    # Create some existing posts
    Post.create!(
      post_type: @blog_type,
      title: "Existing Post",
      slug: "existing-post",
      content: "Test content",
      status: "published",
      published_at: Time.now
    )

    assert_equal 1, Post.count

    ENV["COUNT"] = "2"
    ENV["CLEAR"] = "true"

    run_rake_task("bunko:sample_data")

    # Should have new posts only (old one cleared)
    assert_equal 6, Post.count # 2 posts × 3 post types
    refute Post.exists?(slug: "existing-post")
  ensure
    ENV.delete("COUNT")
    ENV.delete("CLEAR")
  end

  def test_sample_data_preserves_existing_by_default
    # Create an existing post
    Post.create!(
      post_type: @blog_type,
      title: "Existing Post",
      slug: "existing-post",
      content: "Test content",
      status: "published",
      published_at: Time.now
    )

    assert_equal 1, Post.count

    ENV["COUNT"] = "2"

    run_rake_task("bunko:sample_data")

    # Should have old + new posts
    assert_equal 7, Post.count # 1 existing + (2 × 3 new)
    assert Post.exists?(slug: "existing-post")
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_creates_posts_with_all_required_fields
    ENV["COUNT"] = "1"

    run_rake_task("bunko:sample_data")

    post = Post.first
    refute_nil post.title
    refute_nil post.slug
    refute_nil post.content
    refute_nil post.meta_description
    refute_nil post.title_tag
    assert_equal "published", post.status
    refute_nil post.published_at
    refute_nil post.post_type
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_creates_unique_slugs
    ENV["COUNT"] = "10"

    run_rake_task("bunko:sample_data")

    blog_posts = Post.where(post_type: @blog_type)
    slugs = blog_posts.pluck(:slug)

    # All slugs should be unique
    assert_equal slugs.length, slugs.uniq.length
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_creates_mostly_past_dates
    ENV["COUNT"] = "20"

    run_rake_task("bunko:sample_data")

    past_count = Post.where("published_at < ?", Time.now).count
    future_count = Post.where("published_at > ?", Time.now).count

    # Should be roughly 90% past, 10% future (54 past, 6 future out of 60 total)
    # Allow some variance
    assert past_count > 45, "Expected mostly past dates, got #{past_count} past and #{future_count} future"
    assert future_count > 0, "Expected some future dates, got #{future_count}"
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_respects_word_count_range
    ENV["COUNT"] = "5"
    ENV["MIN_WORDS"] = "100"
    ENV["MAX_WORDS"] = "200"

    run_rake_task("bunko:sample_data")

    Post.all.each do |post|
      word_count = post.content.split.length
      # Allow significant variance due to structured content (headings, code blocks, etc.)
      # Content generators add structure that increases word count
      assert word_count >= 50, "Post has #{word_count} words, expected at least 50"
      assert word_count <= 400, "Post has #{word_count} words, expected at most 400"
    end
  ensure
    ENV.delete("COUNT")
    ENV.delete("MIN_WORDS")
    ENV.delete("MAX_WORDS")
  end

  def test_sample_data_generates_consistent_content_structure
    ENV["COUNT"] = "1"

    run_rake_task("bunko:sample_data")

    # All posts should have the same generic structure now
    # Check blog post has summary and subheadings
    blog_post = Post.where(post_type: @blog_type).first
    assert_match(/Summary/, blog_post.content)
    assert_match(/Key Points/, blog_post.content)
    assert_match(/Implementation Details/, blog_post.content)

    # Check docs post has same structure (no longer type-specific)
    docs_post = Post.where(post_type: @docs_type).first
    assert_match(/Summary/, docs_post.content)
    assert_match(/Key Points/, docs_post.content)

    # All posts should have generic titles now (no version numbers)
    changelog_post = Post.where(post_type: @changelog_type).first
    assert_kind_of String, changelog_post.title
    assert changelog_post.title.length > 0
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_exits_when_no_post_types_exist
    # Remove all post types
    PostType.delete_all

    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:sample_data")
      end
    end

    assert_match(/No post types found/, output.join)
    assert_match(/rails bunko:setup/, output.join)
  end

  def test_sample_data_calculates_word_count
    ENV["COUNT"] = "1"

    run_rake_task("bunko:sample_data")

    Post.all.each do |post|
      # Word count should be set automatically by the Post model
      refute_nil post.word_count
      assert post.word_count > 0
    end
  ensure
    ENV.delete("COUNT")
  end

  def test_sample_data_with_markdown_format
    ENV["COUNT"] = "2"
    ENV["FORMAT"] = "markdown"

    run_rake_task("bunko:sample_data")

    # Check that posts contain markdown formatting
    Post.all.each do |post|
      # Should have markdown headings
      assert_match(/## \w+/, post.content)
    end
  ensure
    ENV.delete("COUNT")
    ENV.delete("FORMAT")
  end

  def test_sample_data_with_html_format
    ENV["COUNT"] = "2"
    ENV["FORMAT"] = "html"

    run_rake_task("bunko:sample_data")

    # Check that posts contain HTML tags
    Post.all.each do |post|
      # Should have HTML headings
      assert_match(/<h2/, post.content)
      # Should have HTML paragraphs
      assert_match(/<p/, post.content)
    end
  ensure
    ENV.delete("COUNT")
    ENV.delete("FORMAT")
  end

  def test_sample_data_with_invalid_format
    ENV["COUNT"] = "1"
    ENV["FORMAT"] = "invalid"

    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:sample_data")
      end
    end

    assert_match(/Invalid format: invalid/, output.join)
    assert_match(/Valid formats:/, output.join)
  ensure
    ENV.delete("COUNT")
    ENV.delete("FORMAT")
  end

  def test_sample_data_default_format_is_html
    ENV["COUNT"] = "1"
    # Don't set FORMAT, should default to HTML

    run_rake_task("bunko:sample_data")

    post = Post.first
    # HTML format should have HTML tags, not markdown
    assert_match(/<h2/, post.content)
    assert_match(/<p/, post.content)
    refute_match(/^## \w+/, post.content)
  ensure
    ENV.delete("COUNT")
  end

  private

  def run_rake_task(task_name, *args)
    task = Rake::Task[task_name]
    task.reenable # Allow the task to be run multiple times in tests
    task.invoke(*args)
  end
end
