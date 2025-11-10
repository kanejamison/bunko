# frozen_string_literal: true

require "erb"
require "fileutils"

namespace :bunko do
  desc "Set up Bunko by creating all configured PostTypes and Collections"
  task setup: :environment do
    puts "Setting up Bunko..."
    puts ""

    post_types = Bunko.configuration.post_types
    collections = Bunko.configuration.collections

    if post_types.empty?
      puts "⚠️  No post types configured."
      puts "   Add them to config/initializers/bunko.rb and run this task again."
      puts ""
      puts "   Example:"
      puts "   config.post_type \"blog\""
      puts "   config.post_type \"docs\" do |type|"
      puts "     type.title = \"Documentation\""
      puts "   end"
      exit
    end

    # Generate shared navigation once
    puts "Generating shared navigation..."
    generate_shared_nav
    puts ""

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

  # Helper methods

  def generate_shared_nav
    shared_dir = Rails.root.join("app/views/shared")
    nav_file = shared_dir.join("_bunko_nav.html.erb")

    if File.exist?(nav_file)
      puts "  - _bunko_nav.html.erb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(shared_dir)

    nav_content = render_template("bunko_nav.html.erb.tt", {
      post_types: Bunko.configuration.post_types,
      collections: Bunko.configuration.collections
    })
    File.write(nav_file, nav_content)

    puts "  ✓ Created shared/_bunko_nav.html.erb"
    true
  end

  def render_template(template_name, locals = {})
    template_path = File.expand_path("../templates/#{template_name}", __dir__)

    unless File.exist?(template_path)
      raise "Template file not found: #{template_path}"
    end

    template_content = File.read(template_path)

    # Create a binding with the local variables
    b = binding
    locals.each do |key, value|
      b.local_variable_set(key, value)
    end

    ERB.new(template_content, trim_mode: "-").result(b)
  end
end
