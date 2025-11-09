# frozen_string_literal: true

require "erb"
require "fileutils"

namespace :bunko do
  desc "Set up Bunko by creating PostTypes and generating controllers/views/routes. Optional: rails bunko:setup[slug] to set up a specific post type."
  task :setup, [:slug] => :environment do |t, args|
    puts "Setting up Bunko..."
    puts ""

    post_types = Bunko.configuration.post_types

    if post_types.empty?
      puts "⚠️  No post types configured."
      puts "   Add them to config/initializers/bunko.rb and run this task again."
      puts ""
      puts "   Example:"
      puts "   config.post_types = ["
      puts "     { name: \"Blog\", slug: \"blog\" },"
      puts "     { name: \"Documentation\", slug: \"docs\" }"
      puts "   ]"
      exit
    end

    # If a specific slug was provided, filter to just that one
    if args[:slug]
      target_slug = args[:slug]
      post_types = post_types.select { |pt| pt[:slug] == target_slug }

      if post_types.empty?
        puts "⚠️  PostType with slug '#{target_slug}' not found in config."
        puts "   Available slugs: #{Bunko.configuration.post_types.map { |pt| pt[:slug] }.join(", ")}"
        puts ""
        puts "   Add it to config/initializers/bunko.rb first:"
        puts "   config.post_types = ["
        puts "     { name: \"#{target_slug.titleize}\", slug: \"#{target_slug}\" }"
        puts "   ]"
        exit
      end

      puts "Setting up PostType: #{target_slug}"
      puts ""
    end

    # Track what we create
    post_types_created = 0
    post_types_existing = 0
    controllers_created = []
    views_created = []
    routes_added = []

    # Step 1: Create PostTypes
    puts "Creating PostTypes..."
    post_types.each do |pt_config|
      post_type = PostType.find_by(slug: pt_config[:slug])

      if post_type
        post_types_existing += 1
        puts "  ✓ PostType already exists: #{pt_config[:name]} (#{pt_config[:slug]})"
      else
        PostType.create!(
          name: pt_config[:name],
          slug: pt_config[:slug]
        )
        post_types_created += 1
        puts "  ✓ Created PostType: #{pt_config[:name]} (#{pt_config[:slug]})"
      end
    end

    puts ""

    # Step 2: Generate controllers for each post type
    puts "Generating controllers..."
    post_types.each do |pt_config|
      controller_created = generate_controller(pt_config[:slug])
      controllers_created << pt_config[:slug] if controller_created
    end

    puts ""

    # Step 3: Generate views for each post type
    puts "Generating views..."
    post_types.each do |pt_config|
      views_generated = generate_views(pt_config[:slug])
      views_created << pt_config[:slug] if views_generated
    end

    puts ""

    # Step 4: Add routes for each post type
    puts "Adding routes..."
    post_types.each do |pt_config|
      route_added = add_route(pt_config[:slug])
      routes_added << pt_config[:slug] if route_added
    end

    puts ""
    puts "=" * 79
    puts "Setup complete!"
    puts ""
    puts "PostTypes:"
    puts "  Created: #{post_types_created}" if post_types_created > 0
    puts "  Already existed: #{post_types_existing}" if post_types_existing > 0
    puts ""
    puts "Controllers: #{controllers_created.size} generated (#{controllers_created.join(", ")})" if controllers_created.any?
    puts "Views: #{views_created.size} collections (#{views_created.join(", ")})" if views_created.any?
    puts "Routes: #{routes_added.size} added (#{routes_added.join(", ")})" if routes_added.any?
    puts ""
    puts "Next steps:"
    puts "  1. Create your first post in the Rails console or admin panel"
    puts "  2. Visit your collections:"
    post_types.each do |pt|
      puts "     http://localhost:3000/#{pt[:slug]}"
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

    route_line = "  resources :#{slug}, only: [:index, :show], param: :slug"

    if routes_content.include?(route_line.strip)
      puts "  - Route for :#{slug} already exists (skipped)"
      return false
    end

    # Find the last 'end' and insert before it
    updated_content = routes_content.sub(/^end\s*$/) do |match|
      "#{route_line}\n#{match}"
    end

    File.write(routes_file, updated_content)
    puts "  ✓ Added route for :#{slug}"
    true
  end

  def render_template(template_name, locals = {})
    template_path = File.expand_path("../tasks/templates/#{template_name}", __dir__)
    template_content = File.read(template_path)

    # Create a binding with the local variables
    b = binding
    locals.each do |key, value|
      b.local_variable_set(key, value)
    end

    ERB.new(template_content, trim_mode: "-").result(b)
  end
end
