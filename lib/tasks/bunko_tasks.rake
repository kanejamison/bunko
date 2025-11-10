# frozen_string_literal: true

require "erb"
require "fileutils"

namespace :bunko do
  desc "Set up Bunko by creating PostTypes and generating controllers/views/routes. Optional: rails bunko:setup[name] to set up a specific post type."
  task :setup, [:name] => :environment do |t, args|
    puts "Setting up Bunko..."
    puts ""

    post_types = Bunko.configuration.post_types

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

    # If a specific name was provided, filter to just that one
    if args[:name]
      target_name = args[:name]
      post_types = post_types.select { |pt| pt[:name] == target_name }

      if post_types.empty?
        puts "⚠️  PostType with name '#{target_name}' not found in config."
        puts "   Available names: #{Bunko.configuration.post_types.map { |pt| pt[:name] }.join(", ")}"
        puts ""
        puts "   Add it to config/initializers/bunko.rb first:"
        puts "   config.post_type \"#{target_name}\""
        exit
      end

      puts "Setting up PostType: #{target_name}"
      puts ""
    end

    # Track what we create
    post_types_created = 0
    post_types_existing = 0
    controllers_created = []
    views_created = []
    routes_added = []

    collections = Bunko.configuration.collections

    # Validate post_types configuration
    post_types.each do |pt_config|
      unless pt_config.is_a?(Hash) && pt_config[:name] && pt_config[:title]
        puts "⚠️  Invalid post type configuration: #{pt_config.inspect}"
        puts "   Each post type must be a hash with :name and :title keys."
        puts "   Example: { name: \"blog\", title: \"Blog\" }"
        exit
      end
    end

    # Step 1: Create PostTypes
    puts "Creating PostTypes..."
    post_types.each do |pt_config|
      post_type = PostType.find_by(name: pt_config[:name])

      if post_type
        post_types_existing += 1
        puts "  ✓ PostType already exists: #{pt_config[:title]} (#{pt_config[:name]})"
      else
        PostType.create!(
          name: pt_config[:name],
          title: pt_config[:title]
        )
        post_types_created += 1
        puts "  ✓ Created PostType: #{pt_config[:title]} (#{pt_config[:name]})"
      end
    end

    puts ""

    # Step 2: Generate controllers for each post type
    puts "Generating controllers..."
    post_types.each do |pt_config|
      controller_created = generate_controller(pt_config[:name])
      controllers_created << pt_config[:name] if controller_created
    end

    puts ""

    # Step 3: Generate views for each post type
    puts "Generating views..."
    post_types.each do |pt_config|
      views_generated = generate_views(pt_config[:name])
      views_created << pt_config[:name] if views_generated
    end

    puts ""

    # Step 4: Add routes for each post type
    puts "Adding routes..."
    post_types.each do |pt_config|
      route_added = add_route(pt_config[:name])
      routes_added << pt_config[:name] if route_added
    end

    puts ""

    # Step 5: Generate controllers for each collection
    if collections.any?
      puts "Generating collection controllers..."
      collections.each do |collection_config|
        controller_created = generate_controller(collection_config[:slug])
        controllers_created << collection_config[:slug] if controller_created
      end

      puts ""

      # Step 6: Generate views for each collection
      puts "Generating collection views..."
      collections.each do |collection_config|
        views_generated = generate_views(collection_config[:slug])
        views_created << collection_config[:slug] if views_generated
      end

      puts ""

      # Step 7: Add routes for each collection
      puts "Adding collection routes..."
      collections.each do |collection_config|
        route_added = add_route(collection_config[:slug])
        routes_added << collection_config[:slug] if route_added
      end

      puts ""
    end

    puts "=" * 79
    puts "Setup complete!"
    puts ""

    if post_types_created > 0 || post_types_existing > 0
      puts "PostTypes:"
      puts "  Created: #{post_types_created}" if post_types_created > 0
      puts "  Already existed: #{post_types_existing}" if post_types_existing > 0
      puts ""
    end

    if collections.any?
      puts "Collections: #{collections.size} configured (#{collections.map { |c| c[:slug] }.join(", ")})"
      puts ""
    end

    puts "Controllers: #{controllers_created.size} generated (#{controllers_created.join(", ")})" if controllers_created.any?
    puts "Views: #{views_created.size} generated (#{views_created.join(", ")})" if views_created.any?
    puts "Routes: #{routes_added.size} added (#{routes_added.join(", ")})" if routes_added.any?
    puts ""
    puts "Next steps:"
    puts "  1. Create your first post in the Rails console or admin panel"
    puts "  2. Visit your collections:"

    # Show PostType routes (convert underscores to hyphens for URLs)
    post_types.each do |pt|
      url_path = pt[:name].tr("_", "-")
      puts "     http://localhost:3000/#{url_path}"
    end

    # Show Collection routes
    collections.each do |c|
      puts "     http://localhost:3000/#{c[:slug]} (collection: #{c[:post_types].join(", ")})"
    end

    puts "=" * 79
  end

  def generate_controller(slug)
    controller_name = "#{slug.camelize}Controller"
    controller_file = Rails.root.join("app/controllers/#{slug}_controller.rb")

    if File.exist?(controller_file)
      puts "  - #{slug}_controller.rb already exists (skipped)"
      return false
    end

    controller_content = render_template("controller.rb.tt", {
      controller_name: controller_name,
      slug: slug
    })

    File.write(controller_file, controller_content)
    puts "  ✓ Created #{slug}_controller.rb"
    true
  end

  def generate_views(slug)
    views_dir = Rails.root.join("app/views/#{slug}")

    if Dir.exist?(views_dir) && Dir.glob("#{views_dir}/*").any?
      puts "  - #{slug} views already exist (skipped)"
      return false
    end

    FileUtils.mkdir_p(views_dir)

    # Generate index.html.erb
    index_content = generate_index_view(slug)
    File.write(File.join(views_dir, "index.html.erb"), index_content)

    # Generate show.html.erb
    show_content = generate_show_view(slug)
    File.write(File.join(views_dir, "show.html.erb"), show_content)

    puts "  ✓ Created views for #{slug} (index, show)"
    true
  end

  def generate_index_view(slug)
    render_template("index.html.erb.tt", {
      slug: slug,
      collection_title: slug.titleize,
      path_helper: "#{slug}_path",
      index_path_helper: "#{slug}_index_path"
    })
  end

  def generate_show_view(slug)
    render_template("show.html.erb.tt", {
      slug: slug,
      collection_title: slug.titleize,
      index_path_helper: "#{slug}_index_path"
    })
  end

  def add_route(slug)
    routes_file = Rails.root.join("config/routes.rb")
    routes_content = File.read(routes_file)

    route_line = "  bunko_collection :#{slug}"

    if routes_content.include?(route_line.strip)
      puts "  - Route for :#{slug} already exists (skipped)"
      return false
    end

    # Find the last 'end' in the file and insert before it
    # This handles the closing end of Rails.application.routes.draw
    lines = routes_content.lines
    last_end_index = lines.rindex { |line| line.match?(/^end\s*$/) }

    if last_end_index
      lines.insert(last_end_index, "#{route_line}\n")
      updated_content = lines.join
    else
      # Fallback: append before the last line if no 'end' found
      updated_content = routes_content.sub(/\z/, "#{route_line}\n")
    end

    File.write(routes_file, updated_content)
    puts "  ✓ Added route for :#{slug}"
    true
  end

  def render_template(template_name, locals = {})
    template_path = File.expand_path("templates/#{template_name}", __dir__)

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
