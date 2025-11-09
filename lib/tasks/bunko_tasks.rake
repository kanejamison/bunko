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

    controller_content = <<~RUBY
      # frozen_string_literal: true

      class #{controller_name} < ApplicationController
        bunko_collection :#{slug}

        # The bunko_collection method automatically provides index and show actions.
        #
        # To customize, you can override these methods:
        #
        # def index
        #   super # calls bunko_collection's index
        #   # Add your customizations here
        # end
        #
        # def show
        #   super # calls bunko_collection's show
        #   # Add your customizations here
        # end
        #
        # Available instance variables in your views:
        # - @posts (index action)
        # - @post (show action)
        # - @collection_name
        # - @pagination
      end
    RUBY

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
    collection_title = slug.titleize
    path_helper = "#{slug}_path"
    index_path_helper = "#{slug}_index_path"

    <<~ERB
      <div class="#{slug}-index">
        <h1>#{collection_title}</h1>

        <% if @posts.any? %>
          <div class="posts">
            <% @posts.each do |post| %>
              <article class="post-preview">
                <h2>
                  <%= link_to post.title, #{path_helper}(post.slug) %>
                </h2>

                <div class="post-meta">
                  <% if post.published_at %>
                    <time datetime="<%= post.published_at.iso8601 %>">
                      <%= post.published_at.strftime("%B %d, %Y") %>
                    </time>
                  <% end %>

                  <% if post.reading_time %>
                    <span class="reading-time">
                      <%= post.reading_time %> min read
                    </span>
                  <% end %>
                </div>

                <% if post.content.present? %>
                  <div class="post-excerpt">
                    <%= truncate(post.content, length: 200) %>
                  </div>
                <% end %>
              </article>
            <% end %>
          </div>

          <% if @pagination[:total_pages] > 1 %>
            <nav class="pagination">
              <% if @pagination[:prev_page] %>
                <%= link_to "← Previous", #{index_path_helper}(page: @pagination[:page] - 1), class: "pagination-prev" %>
              <% end %>

              <span class="pagination-info">
                Page <%= @pagination[:page] %> of <%= @pagination[:total_pages] %>
              </span>

              <% if @pagination[:next_page] %>
                <%= link_to "Next →", #{index_path_helper}(page: @pagination[:page] + 1), class: "pagination-next" %>
              <% end %>
            </nav>
          <% end %>
        <% else %>
          <p class="no-posts">No #{collection_title.downcase} posts yet.</p>
        <% end %>
      </div>
    ERB
  end

  def generate_show_view(slug)
    index_path_helper = "#{slug}_index_path"
    collection_title = slug.titleize

    <<~ERB
      <article class="post">
        <header class="post-header">
          <h1><%= @post.title %></h1>

          <div class="post-meta">
            <% if @post.published_at %>
              <time datetime="<%= @post.published_at.iso8601 %>">
                <%= @post.published_at.strftime("%B %d, %Y") %>
              </time>
            <% end %>

            <% if @post.reading_time %>
              <span class="reading-time">
                <%= @post.reading_time %> min read
              </span>
            <% end %>
          </div>
        </header>

        <div class="post-content">
          <%= simple_format(@post.content) %>
        </div>

        <footer class="post-footer">
          <%= link_to "← Back to #{collection_title}", #{index_path_helper}, class: "back-link" %>
        </footer>
      </article>
    ERB
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
end
