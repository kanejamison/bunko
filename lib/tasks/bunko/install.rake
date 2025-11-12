# frozen_string_literal: true

require "erb"
require "fileutils"

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
    create_post_types_migration(skip_seo: skip_seo, json_content: json_content)
    sleep 1 # Ensure different timestamps
    create_posts_migration(skip_seo: skip_seo, json_content: json_content)
    puts ""

    # Step 2: Create models
    puts "Creating models..."
    create_models
    puts ""

    # Step 3: Create initializer
    puts "Creating initializer..."
    create_initializer
    puts ""

    # Step 4: Show instructions
    show_install_instructions
  end

  # Helper methods

  def create_post_types_migration(skip_seo:, json_content:)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    migration_file = Rails.root.join("db/migrate/#{timestamp}_create_post_types.rb")

    if Dir.glob(Rails.root.join("db/migrate/*_create_post_types.rb")).any?
      puts "  - create_post_types migration already exists (skipped)"
      return false
    end

    migration_content = render_template("create_post_types.rb.tt", {
      skip_seo: skip_seo,
      json_content: json_content
    })

    File.write(migration_file, migration_content)
    puts "  ✓ Created db/migrate/#{timestamp}_create_post_types.rb"
    true
  end

  def create_posts_migration(skip_seo:, json_content:)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    migration_file = Rails.root.join("db/migrate/#{timestamp}_create_posts.rb")

    if Dir.glob(Rails.root.join("db/migrate/*_create_posts.rb")).any?
      puts "  - create_posts migration already exists (skipped)"
      return false
    end

    migration_content = render_template("create_posts.rb.tt", {
      skip_seo: skip_seo,
      json_content: json_content
    })

    File.write(migration_file, migration_content)
    puts "  ✓ Created db/migrate/#{timestamp}_create_posts.rb"
    true
  end

  def create_models
    # Create Post model
    post_file = Rails.root.join("app/models/post.rb")
    if File.exist?(post_file)
      puts "  - app/models/post.rb already exists (skipped)"
    else
      post_content = render_template("post.rb.tt", {})
      File.write(post_file, post_content)
      puts "  ✓ Created app/models/post.rb"
    end

    # Create PostType model
    post_type_file = Rails.root.join("app/models/post_type.rb")
    if File.exist?(post_type_file)
      puts "  - app/models/post_type.rb already exists (skipped)"
    else
      post_type_content = render_template("post_type.rb.tt", {})
      File.write(post_type_file, post_type_content)
      puts "  ✓ Created app/models/post_type.rb"
    end
  end

  def create_initializer
    initializer_dir = Rails.root.join("config/initializers")
    initializer_file = initializer_dir.join("bunko.rb")

    if File.exist?(initializer_file)
      puts "  - config/initializers/bunko.rb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(initializer_dir)
    initializer_content = render_template("bunko.rb.tt", {})
    File.write(initializer_file, initializer_content)
    puts "  ✓ Created config/initializers/bunko.rb"
    true
  end

  def show_install_instructions
    instructions_path = File.expand_path("../templates/INSTALL.md", __dir__)
    instructions = File.read(instructions_path)

    puts "=" * 79
    puts instructions
    puts "=" * 79
  end

  def render_template(template_name, locals = {})
    template_path = File.expand_path("../templates/#{template_name}", __dir__)

    unless File.exist?(template_path)
      raise "Template file not found: #{template_path}"
    end

    template_content = File.read(template_path)

    # Create an object with helper methods for the template
    skip_seo = locals[:skip_seo]
    json_content = locals[:json_content]

    context = Object.new
    context.define_singleton_method(:include_seo_fields?) { !skip_seo }
    context.define_singleton_method(:use_json_content?) { json_content }

    ERB.new(template_content, trim_mode: "-").result(context.instance_eval { binding })
  end
end
