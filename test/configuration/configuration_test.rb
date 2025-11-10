# frozen_string_literal: true

require_relative "../test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  def setup
    # Reset configuration before each test
    Bunko.reset_configuration!
  end

  def teardown
    # Clean up after each test
    Bunko.reset_configuration!
  end

  test "allows defining post types" do
    Bunko.configure do |config|
      config.post_type "Blog"
      config.post_type "Docs"
    end

    assert_equal 2, Bunko.configuration.post_types.size
    assert_equal "blog", Bunko.configuration.post_types.first[:slug]
    assert_equal "docs", Bunko.configuration.post_types.last[:slug]
  end

  test "allows defining collections with post_types" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.post_type "Videos"
      config.collection "blog", post_types: ["articles", "videos"]
    end

    assert_equal 1, Bunko.configuration.collections.size
    collection = Bunko.configuration.collections.first
    assert_equal "blog", collection[:slug]
    assert_equal ["articles", "videos"], collection[:post_types]
  end

  test "allows defining collection with scope block" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.post_type "Videos"
      config.collection "featured", post_types: ["articles", "videos"] do |c|
        c.scope -> { where(featured: true) }
      end
    end

    collection = Bunko.configuration.collections.first
    assert_not_nil collection[:scope]
    assert collection[:scope].is_a?(Proc)
  end

  test "raises error when post_type conflicts with existing collection" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.collection "blog", post_types: ["articles"]
        config.post_type "Blog"  # Conflict!
      end
    end

    assert_match(/conflicts with existing collection/, error.message)
  end

  test "raises error when collection conflicts with existing post_type" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "Blog"
        config.collection "blog", post_types: ["articles"]  # Conflict!
      end
    end

    assert_match(/conflicts with existing PostType/, error.message)
  end

  test "raises error when collection already exists" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "Articles"
        config.collection "featured", post_types: ["articles"]
        config.collection "featured", post_types: ["articles"]  # Duplicate!
      end
    end

    assert_match(/already exists/, error.message)
  end

  test "find_post_type returns post_type config by slug" do
    Bunko.configure do |config|
      config.post_type "Blog"
      config.post_type "Docs"
    end

    blog = Bunko.configuration.find_post_type("blog")
    assert_not_nil blog
    assert_equal "blog", blog[:slug]

    nonexistent = Bunko.configuration.find_post_type("nonexistent")
    assert_nil nonexistent
  end

  test "find_collection returns collection config by slug" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.collection "featured", post_types: ["articles"]
    end

    featured = Bunko.configuration.find_collection("featured")
    assert_not_nil featured
    assert_equal "featured", featured[:slug]

    nonexistent = Bunko.configuration.find_collection("nonexistent")
    assert_nil nonexistent
  end

  test "normalizes collection name to slug" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.collection "Featured Articles", post_types: ["articles"]
    end

    collection = Bunko.configuration.collections.first
    assert_equal "featured-articles", collection[:slug]
  end

  test "normalizes post_types array to slugs" do
    Bunko.configure do |config|
      config.post_type "Articles"
      config.post_type "Videos"
      config.collection "blog", post_types: ["Articles", "Video Tutorials"]
    end

    collection = Bunko.configuration.collections.first
    assert_equal ["articles", "video-tutorials"], collection[:post_types]
  end
end
