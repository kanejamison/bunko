# frozen_string_literal: true

# Bunko configuration for test dummy app
Bunko.configure do |config|
  # PostTypes
  config.post_type "blog"
  config.post_type "docs"
  config.post_type "articles"
  config.post_type "videos"

  # Collections
  config.collection "long_reads" do |c|
    c.post_types = ["articles"]
    c.scope = -> { where("word_count > ?", 1500) }
  end

  config.collection "all_content" do |c|
    c.post_types = ["articles", "videos"]
  end
end
