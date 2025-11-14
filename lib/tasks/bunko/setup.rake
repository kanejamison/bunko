# frozen_string_literal: true

require "erb"
require "fileutils"
require "ostruct"

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
    generate_shared_nav
    generate_shared_styles
    generate_shared_footer
    puts ""

    # Set up static pages if enabled
    if allow_static_pages
      puts "Setting up static pages..."
      setup_static_pages
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

  # Helper methods

  def generate_shared_nav
    shared_dir = Rails.root.join("app/views/shared")
    nav_file = shared_dir.join("_bunko_nav.html.erb")

    if File.exist?(nav_file)
      puts "  - _bunko_nav.html.erb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(shared_dir)

    nav_content = render_template("views/layouts/bunko_nav.html.erb.tt", {})
    File.write(nav_file, nav_content)

    puts "  ✓ Created shared/_bunko_nav.html.erb"
    true
  end

  def generate_shared_styles
    shared_dir = Rails.root.join("app/views/shared")
    styles_file = shared_dir.join("_bunko_styles.html.erb")

    if File.exist?(styles_file)
      puts "  - _bunko_styles.html.erb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(shared_dir)

    styles_content = render_template("views/layouts/bunko_styles.html.erb.tt", {})
    File.write(styles_file, styles_content)

    puts "  ✓ Created shared/_bunko_styles.html.erb"
    true
  end

  def generate_shared_footer
    shared_dir = Rails.root.join("app/views/shared")
    footer_file = shared_dir.join("_bunko_footer.html.erb")

    if File.exist?(footer_file)
      puts "  - _bunko_footer.html.erb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(shared_dir)

    footer_content = render_template("views/layouts/bunko_footer.html.erb.tt", {})
    File.write(footer_file, footer_content)

    puts "  ✓ Created shared/_bunko_footer.html.erb"
    true
  end

  def render_template(template_name, locals = {})
    template_path = File.expand_path("../templates/#{template_name}", __dir__)

    unless File.exist?(template_path)
      raise "Template file not found: #{template_path}"
    end

    template_content = File.read(template_path)

    # Create a context object with all local variables as methods
    context = OpenStruct.new(locals)

    ERB.new(template_content, trim_mode: "-").result(context.instance_eval { binding })
  end

  def setup_static_pages
    # Create "pages" PostType in database
    PostType.find_or_create_by!(name: "pages") do |pt|
      pt.title = "Pages"
    end
    puts "  ✓ Created 'pages' PostType in database"

    # Generate PagesController
    generate_pages_controller

    # Generate pages/show.html.erb view
    generate_pages_show_view
  end

  def generate_pages_controller
    controller_path = Rails.root.join("app/controllers/pages_controller.rb")

    if File.exist?(controller_path)
      puts "  - pages_controller.rb already exists (skipped)"
      return false
    end

    controller_content = render_template("controllers/pages_controller.rb.tt", {})
    File.write(controller_path, controller_content)

    puts "  ✓ Created app/controllers/pages_controller.rb"
    true
  end

  def generate_pages_show_view
    views_dir = Rails.root.join("app/views/pages")
    show_file = views_dir.join("show.html.erb")

    if File.exist?(show_file)
      puts "  - pages/show.html.erb already exists (skipped)"
      return false
    end

    FileUtils.mkdir_p(views_dir)

    show_content = render_template("views/pages/show.html.erb.tt", {})
    File.write(show_file, show_content)

    puts "  ✓ Created app/views/pages/show.html.erb"
    true
  end
end
