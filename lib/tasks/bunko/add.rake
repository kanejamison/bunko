# frozen_string_literal: true

require "erb"
require "fileutils"

namespace :bunko do
  desc "Add a PostType or Collection (automatically detects which)"
  task :add, [:name] => :environment do |t, args|
    unless args[:name]
      puts "⚠️  Please provide a name"
      puts "   Usage: rails bunko:add[blog]"
      exit 1
    end

    name = args[:name]
    format = ENV.fetch("FORMAT", "html").downcase

    # Validate format
    valid_formats = %w[plain html]
    unless valid_formats.include?(format)
      puts "⚠️  Invalid format: #{format}"
      puts "    Valid formats: #{valid_formats.join(", ")}"
      exit 1
    end

    # Check if it's a PostType
    pt_config = Bunko.configuration.post_types.find { |pt| pt[:name] == name }

    # Check if it's a Collection
    collection_config = Bunko.configuration.collections.find { |c| c[:slug] == name }

    unless pt_config || collection_config
      # Not found in either
      puts "⚠️  '#{name}' not found in configuration"
      puts ""

      available_post_types = Bunko.configuration.post_types.map { |pt| pt[:name] }
      available_collections = Bunko.configuration.collections.map { |c| c[:slug] }

      if available_post_types.any?
        puts "   Available PostTypes: #{available_post_types.join(", ")}"
      end

      if available_collections.any?
        puts "   Available Collections: #{available_collections.join(", ")}"
      end

      puts ""
      puts "   Add it to config/initializers/bunko.rb first:"
      puts "   config.post_type \"#{name}\""
      puts "   # or"
      puts "   config.collection \"#{name.titleize}\", post_types: [...]"
      exit 1
    end

    # Step 1: If it's a PostType, create DB entry
    if pt_config
      create_post_type_in_database(name, pt_config[:title])
    end

    # Step 2: Always generate artifacts (for both PostTypes and Collections)
    generate_artifacts(name, format: format)

    # Step 3: Add to nav
    if pt_config
      add_to_nav(name, title: pt_config[:title])
    else
      add_to_nav(name, title: collection_config[:name].titleize)
    end

    # Success message
    puts ""
    if pt_config
      puts "PostType '#{name}' added successfully!"
    else
      puts "Collection '#{name}' added successfully!"
    end
    puts "Visit: http://localhost:3000/#{name.tr("_", "-")}"
  end

  # Helper methods

  def create_post_type_in_database(name, title)
    post_type = PostType.find_by(name: name)

    if post_type
      puts "  ✓ PostType already exists: #{title} (#{name})"
    else
      PostType.create!(name: name, title: title)
      puts "  ✓ Created PostType: #{title} (#{name})"
    end
    puts ""
  end

  def generate_artifacts(name, format:)
    # Step 1: Generate controller
    puts "Generating controller..."
    generate_controller(name)
    puts ""

    # Step 2: Generate views
    puts "Generating views..."
    generate_views(name, format: format)
    puts ""

    # Step 3: Add route
    puts "Adding route..."
    add_route(name)
  end

  def generate_controller(collection_name)
    controller_name = "#{collection_name.camelize}Controller"
    controller_file = Rails.root.join("app/controllers/#{collection_name}_controller.rb")

    if File.exist?(controller_file)
      puts "  - #{collection_name}_controller.rb already exists (skipped)"
      return false
    end

    controller_content = render_template("controller.rb.tt", {
      controller_name: controller_name,
      collection_name: collection_name
    })

    File.write(controller_file, controller_content)
    puts "  ✓ Created #{collection_name}_controller.rb"
    true
  end

  def generate_views(collection_name, format:)
    views_dir = Rails.root.join("app/views/#{collection_name}")

    if Dir.exist?(views_dir) && Dir.glob("#{views_dir}/*").any?
      puts "  - #{collection_name} views already exist (skipped)"
      return false
    end

    FileUtils.mkdir_p(views_dir)

    # Generate index.html.erb
    index_content = generate_index_view(collection_name)
    File.write(File.join(views_dir, "index.html.erb"), index_content)

    # Generate show.html.erb
    show_content = generate_show_view(collection_name, format: format)
    File.write(File.join(views_dir, "show.html.erb"), show_content)

    puts "  ✓ Created views for #{collection_name} (index, show)"
    true
  end

  def generate_index_view(collection_name)
    is_plural = collection_name.pluralize == collection_name

    render_template("index.html.erb.tt", {
      collection_name: collection_name,
      collection_title: collection_name.titleize,
      path_helper: "#{collection_name.singularize}_path",
      index_path_helper: is_plural ? "#{collection_name}_path" : "#{collection_name}_index_path"
    })
  end

  def generate_show_view(collection_name, format:)
    is_plural = collection_name.pluralize == collection_name

    render_template("show.html.erb.tt", {
      collection_name: collection_name,
      collection_title: collection_name.titleize,
      index_path_helper: is_plural ? "#{collection_name}_path" : "#{collection_name}_index_path",
      format: format
    })
  end

  def add_route(collection_name)
    routes_file = Rails.root.join("config/routes.rb")
    routes_content = File.read(routes_file)

    route_line = "  bunko_collection :#{collection_name}"

    if routes_content.include?(route_line.strip)
      puts "  - Route for :#{collection_name} already exists (skipped)"
      return false
    end

    # Find the last 'end' in the file and insert before it
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
    puts "  ✓ Added route for :#{collection_name}"
    true
  end

  def add_to_nav(name, title:)
    shared_dir = Rails.root.join("app/views/shared")
    nav_file = shared_dir.join("_bunko_nav.html.erb")

    # If nav doesn't exist, generate from scratch (edge case)
    unless File.exist?(nav_file)
      FileUtils.mkdir_p(shared_dir)
      nav_content = render_template("bunko_nav.html.erb.tt", {
        post_types: Bunko.configuration.post_types,
        collections: Bunko.configuration.collections
      })
      File.write(nav_file, nav_content)
      puts "  ✓ Created shared/_bunko_nav.html.erb"
      return true
    end

    # Nav exists - append new link to existing file
    nav_content = File.read(nav_file)

    # Generate the new link
    is_plural = name.pluralize == name
    path_helper = is_plural ? "#{name}_path" : "#{name}_index_path"
    new_link = "    <%= link_to \"#{title}\", #{path_helper}, style: \"text-decoration: none; color: #007bff;\" %>\n"

    # Check if link already exists
    if nav_content.include?(new_link.strip)
      puts "  - #{title} already in nav (skipped)"
      return false
    end

    # Try to insert before the marker comment (preferred)
    marker = "<%# bunko_collection_links - additional collections will be added here unless you delete this line %>"
    nav_content = if nav_content.include?(marker)
      nav_content.sub(marker, "#{new_link}    #{marker}")
    else
      # Fallback: Find the closing </div> before </nav> and insert the new link before it
      nav_content.sub(/(\s*)<\/div>\s*<\/nav>/) do
        indent = $1
        "#{new_link}#{indent}</div>\n</nav>"
      end
    end

    File.write(nav_file, nav_content)
    puts "  ✓ Added #{title} to shared/_bunko_nav.html.erb"
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
