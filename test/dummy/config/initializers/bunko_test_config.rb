# frozen_string_literal: true

# Test-specific Bunko configuration for test/dummy
# This file is loaded AFTER bunko.rb and adds additional post_types needed for tests

Bunko.configure do |config|
  # Additional post_types needed by controller tests
  config.post_type "docs" do |type|
    type.title = "Documentation"
  end

  config.post_type "articles" do |type|
    type.title = "Articles"
  end

  config.post_type "videos" do |type|
    type.title = "Videos"
  end

  # Collections for routing tests
  config.collection "long_reads", post_types: ["articles", "blog"]
  config.collection "all_content", post_types: ["articles", "blog", "videos"]
end
