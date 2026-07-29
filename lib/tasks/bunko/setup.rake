# frozen_string_literal: true

require "fileutils"
require_relative "helpers"

namespace :bunko do
  desc "Set up Bunko by creating all configured PostTypes and Collections"
  task setup: :environment do
    puts "Setting up Bunko..."
    puts ""

    post_types = Bunko.configuration.post_types
    collections = Bunko.configuration.collections
    allow_static_pages = Bunko.configuration.allow_static_pages

    if post_types.empty? && !allow_static_pages
      puts "⚠️  No post types configured and static pages are disabled."
      puts "   Either enable static pages or add post types to config/initializers/bunko.rb"
      puts ""
      puts "   Example:"
      puts "   config.allow_static_pages = true"
      puts "   # OR"
      puts "   config.post_type \"blog\""
      puts "   config.post_type \"docs\" do |type|"
      puts "     type.title = \"Documentation\""
      puts "   end"
      exit
    end

    # Generate shared partials once
    puts "Generating shared partials..."
    Bunko::RakeHelpers.generate_shared_nav
    Bunko::RakeHelpers.generate_shared_styles
    Bunko::RakeHelpers.generate_shared_footer
    puts ""

    # Set up static pages if enabled
    if allow_static_pages
      puts "Setting up static pages..."
      Bunko::RakeHelpers.setup_static_pages
      puts ""
    end

    # Add all post types
    post_types.each do |pt_config|
      Rake::Task["bunko:add"].reenable
      Rake::Task["bunko:add"].invoke(pt_config[:name])
    end

    # Add all collections
    collections.each do |collection_config|
      Rake::Task["bunko:add"].reenable
      Rake::Task["bunko:add"].invoke(collection_config[:name])
    end

    puts "=" * 79
    puts "Setup complete!"
    puts ""
    puts "Next steps:"
    puts "  1. Create your first post in the Rails console or admin panel"
    puts "  2. Visit your collections:"

    # Show PostType routes
    post_types.each do |pt|
      url_path = pt[:name].tr("_", "-")
      puts "     http://localhost:3000/#{url_path}"
    end

    # Show Collection routes
    collections.each do |c|
      url_path = c[:name].tr("_", "-")
      puts "     http://localhost:3000/#{url_path} (collection: #{c[:post_types].join(", ")})"
    end

    puts "=" * 79
    puts ""
    puts "To add more later, update your initializer and run:"
    puts "  rails bunko:add[name]"
    puts "=" * 79
  end
end
