# frozen_string_literal: true

require_relative "../test_helper"

class TitleValidationTest < ActiveSupport::TestCase
  def setup
    # Reset configuration before each test
    Bunko.reset_configuration!
  end

  def teardown
    # Clean up after each test
    Bunko.reset_configuration!
  end

  # PostType title validation (keyword argument)

  test "post_type rejects title with double quotes" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: 'My "Great" Blog'
      end
    end

    assert_match(/cannot contain double quotes/, error.message)
  end

  test "post_type rejects title with ERB opening delimiter" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: "Blog <%= User.destroy_all %>"
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "post_type rejects title with ERB closing delimiter" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: "Blog %> injection"
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "post_type rejects title with newline" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: "Blog\nInjected"
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  test "post_type rejects title with carriage return" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: "Blog\rInjected"
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  # PostType title validation (customizer block)

  test "post_type rejects title with double quotes set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog" do |type|
          type.title = 'My "Great" Blog'
        end
      end
    end

    assert_match(/cannot contain double quotes/, error.message)
  end

  test "post_type rejects title with ERB delimiters set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog" do |type|
          type.title = "<%= system('rm -rf') %>"
        end
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "post_type rejects title with newline set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog" do |type|
          type.title = "Blog\nInjected"
        end
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  test "invalid post_type title is not added to configuration" do
    assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "blog", title: 'Bad "Title"'
      end
    end

    assert_empty Bunko.configuration.post_types
  end

  # Collection title validation (keyword argument)

  test "collection rejects title with double quotes" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: 'The "Best" Resources', post_types: ["articles"]
      end
    end

    assert_match(/cannot contain double quotes/, error.message)
  end

  test "collection rejects title with ERB opening delimiter" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: "Resources <% evil %>", post_types: ["articles"]
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "collection rejects title with ERB closing delimiter" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: "Resources %>", post_types: ["articles"]
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "collection rejects title with newline" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: "Resources\nInjected", post_types: ["articles"]
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  test "collection rejects title with carriage return" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: "Resources\r\nInjected", post_types: ["articles"]
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  # Collection title validation (customizer block)

  test "collection rejects title with double quotes set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources" do |c|
          c.title = 'The "Best" Resources'
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/cannot contain double quotes/, error.message)
  end

  test "collection rejects title with ERB delimiters set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources" do |c|
          c.title = "<%= Post.delete_all %>"
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/cannot contain ERB delimiters/, error.message)
  end

  test "collection rejects title with newline set via block" do
    error = assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources" do |c|
          c.title = "Resources\nInjected"
          c.post_types = ["articles"]
        end
      end
    end

    assert_match(/cannot contain newlines/, error.message)
  end

  test "invalid collection title is not added to configuration" do
    assert_raises(ArgumentError) do
      Bunko.configure do |config|
        config.post_type "articles"
        config.collection "resources", title: 'Bad "Title"', post_types: ["articles"]
      end
    end

    assert_empty Bunko.configuration.collections
  end

  # Safe titles still work

  test "post_type accepts title with apostrophe" do
    Bunko.configure do |config|
      config.post_type "blog", title: "Kane's Blog"
    end

    assert_equal "Kane's Blog", Bunko.configuration.post_types.first[:title]
  end

  test "post_type accepts title with ampersand" do
    Bunko.configure do |config|
      config.post_type "news", title: "News & Updates"
    end

    assert_equal "News & Updates", Bunko.configuration.post_types.first[:title]
  end

  test "post_type accepts title with unicode characters" do
    Bunko.configure do |config|
      config.post_type "blog", title: "Café Notes — 日本語ブログ"
    end

    assert_equal "Café Notes — 日本語ブログ", Bunko.configuration.post_types.first[:title]
  end

  test "post_type accepts title with typographic quotes" do
    Bunko.configure do |config|
      config.post_type "blog" do |type|
        type.title = "The “Best” Blog"
      end
    end

    assert_equal "The “Best” Blog", Bunko.configuration.post_types.first[:title]
  end

  test "post_type accepts title with percent and angle brackets when not ERB delimiters" do
    Bunko.configure do |config|
      config.post_type "deals", title: "Deals < 50% off >"
    end

    assert_equal "Deals < 50% off >", Bunko.configuration.post_types.first[:title]
  end

  test "collection accepts title with apostrophe and ampersand" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources", title: "Editor's Picks & Favorites", post_types: ["articles"]
    end

    assert_equal "Editor's Picks & Favorites", Bunko.configuration.collections.first[:title]
  end

  test "collection accepts title with unicode set via block" do
    Bunko.configure do |config|
      config.post_type "articles"
      config.collection "resources" do |c|
        c.title = "Ressourcen für Anfänger"
        c.post_types = ["articles"]
      end
    end

    assert_equal "Ressourcen für Anfänger", Bunko.configuration.collections.first[:title]
  end

  test "auto-generated titles remain valid" do
    Bunko.configure do |config|
      config.post_type "case_studies"
      config.collection "long_reads", post_types: ["case_studies"]
    end

    assert_equal "Case Studies", Bunko.configuration.post_types.first[:title]
    assert_equal "Long Reads", Bunko.configuration.collections.first[:title]
  end
end
