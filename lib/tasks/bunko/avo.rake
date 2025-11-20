# frozen_string_literal: true

require "fileutils"
require_relative "helpers"

namespace :bunko do
  namespace :avo do
    include Bunko::RakeHelpers

    desc "Generate Avo resource for Bunko posts"
    task install: :environment do
      puts "Generating Avo resource for Bunko..."
      puts ""

      # Check if Avo is installed
      begin
        require "avo"
      rescue LoadError
        puts "⚠️  Avo gem not found!"
        puts "   Add 'gem \"avo\"' to your Gemfile and run 'bundle install'"
        puts "   Then run 'rails generate avo:install' before running this task"
        exit 1
      end

      # Check if Avo has been initialized
      avo_initializer = Rails.root.join("config/initializers/avo.rb")
      unless File.exist?(avo_initializer)
        puts "⚠️  Avo not initialized!"
        puts "   Run 'rails generate avo:install' first"
        exit 1
      end

      # Get configured post types for dynamic filters
      post_types = Bunko.configuration.post_types.map { |pt| pt[:name] }

      # Detect editor preference (Avo-specific editors)
      editor_type = ENV.fetch("EDITOR", "markdown") # Options: markdown (marksmith), rhino, tiptap, trix, textarea

      # Generate Avo resource, filters, and actions
      generate_avo_post_resource(post_types, editor_type)
      generate_avo_post_type_filter(post_types) if post_types.any?
      generate_avo_actions

      puts "=" * 79
      puts "Avo resource generated!"
      puts ""
      puts "Next steps:"
      puts "  1. Visit http://localhost:3000/avo to access your admin panel"
      puts "  2. Customize app/avo/resources/post.rb as needed"
      puts ""
      puts "Editor type: #{editor_type}"
      puts "  To change, run: EDITOR=rhino rails bunko:avo:install"
      puts "  Options: markdown (default, uses Marksmith), rhino, tiptap, trix, textarea"
      puts "=" * 79
    end

    private

    def generate_avo_post_resource(post_types, editor_type)
      resources_dir = Rails.root.join("app/avo/resources")
      resource_file = resources_dir.join("post.rb")

      FileUtils.mkdir_p(resources_dir)

      resource_content = render_template(
        "avo/resources/post.rb.tt",
        post_types: post_types,
        editor_type: editor_type
      )

      File.write(resource_file, resource_content)

      puts "  ✓ Created app/avo/resources/post.rb"
      puts "    - Main content area with #{editor_type} editor"
      puts "    - Metadata sidebar with publishing, SEO, and stats"
      puts "    - Post type filters: #{post_types.join(", ")}" if post_types.any?
    end

    def generate_avo_post_type_filter(post_types)
      filters_dir = Rails.root.join("app/avo/filters")
      filter_file = filters_dir.join("post_type_filter.rb")

      FileUtils.mkdir_p(filters_dir)

      filter_content = render_template(
        "avo/filters/post_type_filter.rb.tt",
        post_types: post_types
      )

      File.write(filter_file, filter_content)

      puts "  ✓ Created app/avo/filters/post_type_filter.rb"
    end

    def generate_avo_actions
      actions_dir = Rails.root.join("app/avo/actions")
      FileUtils.mkdir_p(actions_dir)

      # Generate PublishPost action
      publish_action = actions_dir.join("publish_post.rb")
      publish_content = render_template("avo/actions/publish_post.rb.tt", {})
      File.write(publish_action, publish_content)
      puts "  ✓ Created app/avo/actions/publish_post.rb"

      # Generate UnpublishPost action
      unpublish_action = actions_dir.join("unpublish_post.rb")
      unpublish_content = render_template("avo/actions/unpublish_post.rb.tt", {})
      File.write(unpublish_action, unpublish_content)
      puts "  ✓ Created app/avo/actions/unpublish_post.rb"
    end
  end
end
