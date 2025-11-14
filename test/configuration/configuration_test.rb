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
      config.post_type "blog"
      config.post_type "docs"
    end

    assert_equal 2, Bunko.configuration.post_types.size
    assert_equal "blog", Bunko.configuration.post_types.first[:name]
    assert_equal "Blog", Bunko.configuration.post_types.first[:title]
    assert_equal "docs", Bunko.configuration.post_types.last[:name]
    assert_equal "Docs", Bunko.configuration.post_types.last[:title]
  end

  test "allows defining collections with post_types" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    assert_equal 1, Bunko.configuration.collections.size
    collection = Bunko.configuration.collections.first
    assert_equal "resources", collection[:name]
    assert_equal "Resources", collection[:title]
    assert_equal ["articles", "videos"], collection[:post_types]
  end

  test "allows defining collection with scope block" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "featured" do |c|
        c.post_types = ["articles", "videos"]
        c.scope = -> { where(featured: true) }
      end
    end

    collection = Bunko.configuration.collections.first
    assert_not_nil collection[:scope]
    assert collection[:scope].is_a?(Proc)
  end

  test "raises error when post_type conflicts with existing collection" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources" do |c|
          c.post_types = ["articles"]
        end
        config.post_type "resources"  # Conflict!
      end
    end

    assert_match(/conflicts with existing collection/, error.message)
  end

  test "raises error when collection conflicts with existing post_type" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog"
        config.post_type "articles"
        config.collection "blog" do |c|  # Conflict!
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/conflicts with existing PostType/, error.message)
  end

  test "raises error when collection already exists" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "featured" do |c|
          c.post_types = ["articles"]
        end
        config.collection "featured" do |c|  # Duplicate!
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/already exists/, error.message)
  end

  test "find_post_type returns post_type config by name" do
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    blog = Bunko.configuration.find_post_type("blog")
    assert_not_nil blog
    assert_equal "blog", blog[:name]
    assert_equal "Blog", blog[:title]

    nonexistent = Bunko.configuration.find_post_type("nonexistent")
    assert_nil nonexistent
  end

  test "find_collection returns collection config by name" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "featured" do |c|
        c.post_types = ["articles"]
      end
    end

    featured = Bunko.configuration.find_collection("featured")
    assert_not_nil featured
    assert_equal "featured", featured[:name]

    nonexistent = Bunko.configuration.find_collection("nonexistent")
    assert_nil nonexistent
  end

  test "rejects collection name with hyphens" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "long-reads" do |c|
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/cannot contain hyphens/, error.message)
    assert_match(/Use underscores instead/, error.message)
  end

  test "normalizes post_types array to names with underscores" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["Articles", "Video Tutorials"]
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal ["articles", "video_tutorials"], collection[:post_types]
  end

  test "auto-generates title from name" do
    Bunko.configure do |config|
      config.post_type "case_studies"
    end

    post_type = Bunko.configuration.post_types.first
    assert_equal "case_studies", post_type[:name]
    assert_equal "Case Studies", post_type[:title]
  end

  test "rejects name with hyphens" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "case-studies"
      end
    end

    assert_match(/cannot contain hyphens/, error.message)
    assert_match(/Use underscores instead/, error.message)
  end

  test "rejects name with invalid characters" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "Blog!"
      end
    end

    assert_match(/must contain only lowercase letters/, error.message)
  end

  test "accepts custom title" do
    Bunko.configure do |config|
      config.post_type "case_studies" do |type|
        type.title = "Success Stories"
      end
    end

    post_type = Bunko.configuration.post_types.first
    assert_equal "case_studies", post_type[:name]
    assert_equal "Success Stories", post_type[:title]
  end

  test "collection auto-generates title from name" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "long_reads" do |c|
        c.post_types = ["articles"]
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal "long_reads", collection[:name]
    assert_equal "Long Reads", collection[:title]
  end

  test "collection accepts custom title" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "greatest_hits" do |c|
        c.title = "Greatest Hits"
        c.post_types = ["articles"]
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal "greatest_hits", collection[:name]
    assert_equal "Greatest Hits", collection[:title]
  end

  test "collection requires post_types to be set" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources" do |c|
          # No post_types set
        end
      end
    end

    assert_match(/must specify at least one post_type/, error.message)
  end

  test "post_type accepts title as keyword argument" do
    Bunko.configure do |config|
      config.post_type "case_studies", title: "Success Stories"
    end

    post_type = Bunko.configuration.post_types.first
    assert_equal "case_studies", post_type[:name]
    assert_equal "Success Stories", post_type[:title]
  end

  test "post_type block overrides params" do
    Bunko.configure do |config|
      config.post_type "blog", title: "Blog Posts" do |type|
        type.title = "My Blog"  # Block overrides param
      end
    end

    post_type = Bunko.configuration.post_types.first
    assert_equal "blog", post_type[:name]
    assert_equal "My Blog", post_type[:title]  # Block value wins
  end

  test "collection accepts params without block" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources", post_types: ["articles", "videos"]
    end

    collection = Bunko.configuration.collections.first
    assert_equal "resources", collection[:name]
    assert_equal "Resources", collection[:title]
    assert_equal ["articles", "videos"], collection[:post_types]
  end

  test "collection accepts title and post_types as params" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "greatest_hits", title: "Greatest Hits", post_types: ["articles"]
    end

    collection = Bunko.configuration.collections.first
    assert_equal "greatest_hits", collection[:name]
    assert_equal "Greatest Hits", collection[:title]
  end

  test "collection block overrides params" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources", title: "All Resources", post_types: ["articles"] do |c|
        c.title = "My Resources"  # Block overrides param
        c.post_types = ["articles", "videos"]  # Block overrides param
        c.scope = -> { where(featured: true) }
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal "resources", collection[:name]
    assert_equal "My Resources", collection[:title]  # Block value wins
    assert_equal ["articles", "videos"], collection[:post_types]  # Block value wins
    assert_not_nil collection[:scope]
  end

  test "collection requires either params or block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources"
      end
    end

    assert_match(/requires either post_types parameter or a configuration block/, error.message)
  end

  # Override behavior tests - ensures block ALWAYS wins over params
  test "post_type title: block always overrides param" do
    Bunko.configure do |config|
      config.post_type "blog", title: "Param Title" do |type|
        type.title = "Block Title"
      end
    end

    assert_equal "Block Title", Bunko.configuration.post_types.first[:title]
  end

  test "collection title: block always overrides param" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources", title: "Param Title", post_types: ["articles"] do |c|
        c.title = "Block Title"
      end
    end

    assert_equal "Block Title", Bunko.configuration.collections.first[:title]
  end

  test "collection post_types: block always overrides param" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources", post_types: ["articles"] do |c|
        c.post_types = ["videos"]  # Block overrides param
      end
    end

    assert_equal ["videos"], Bunko.configuration.collections.first[:post_types]
  end

  test "collection scope: block sets scope even when params provided" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources", post_types: ["articles"] do |c|
        c.scope = -> { where(featured: true) }
      end
    end

    assert_instance_of Proc, Bunko.configuration.collections.first[:scope]
  end

  test "collection: params alone work without block" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources", title: "Resources", post_types: ["articles"]
    end

    collection = Bunko.configuration.collections.first
    assert_equal "Resources", collection[:title]
    assert_equal ["articles"], collection[:post_types]
    assert_nil collection[:scope]
  end

  test "collection: block alone works without params" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources" do |c|
        c.title = "Resources"
        c.post_types = ["articles"]
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal "Resources", collection[:title]
    assert_equal ["articles"], collection[:post_types]
  end

  test "collection: mixed params and block - block overrides all params" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources",
        title: "Param Title",
        post_types: ["articles"],
        scope: -> { where(status: "published") } do |c|
        # Block overrides everything
        c.title = "Block Title"
        c.post_types = ["videos"]
        c.scope = -> { where(featured: true) }
      end
    end

    collection = Bunko.configuration.collections.first
    assert_equal "Block Title", collection[:title]
    assert_equal ["videos"], collection[:post_types]
    assert_instance_of Proc, collection[:scope]
  end

  # Static pages configuration tests
  test "allow_static_pages defaults to true" do
    config = Bunko.configuration
    assert_equal true, config.allow_static_pages
  end

  test "allow_static_pages can be set to false" do
    Bunko.configure do |config|
      config.allow_static_pages = false
    end

    assert_equal false, Bunko.configuration.allow_static_pages
  end

  test "rejects post_type name 'pages'" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "pages"
      end
    end

    assert_match(/reserved for the static pages feature/, error.message)
    assert_match(/config.allow_static_pages/, error.message)
  end
end
