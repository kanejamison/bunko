# frozen_string_literal: true

require "fileutils"
require_relative "helpers"

namespace :bunko do
  desc "Install Bunko by creating migrations, models, and initializer"
  task install: :environment do
    puts "Installing Bunko..."
    puts ""

    # Parse options from environment variables
    skip_seo = ENV["SKIP_SEO"] == "true"
    json_content = ENV["JSON_CONTENT"] == "true"

    # Step 1: Create migrations
    puts "Creating migrations..."
    Bunko::RakeHelpers.create_post_types_migration(skip_seo: skip_seo, json_content: json_content)
    sleep 1 # Ensure different timestamps
    Bunko::RakeHelpers.create_posts_migration(skip_seo: skip_seo, json_content: json_content)
    puts ""

    # Step 2: Create models
    puts "Creating models..."
    Bunko::RakeHelpers.create_models
    puts ""

    # Step 3: Create initializer
    puts "Creating initializer..."
    Bunko::RakeHelpers.create_initializer
    puts ""

    # Step 4: Show instructions
    Bunko::RakeHelpers.show_install_instructions
  end
end
