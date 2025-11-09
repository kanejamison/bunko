# frozen_string_literal: true

namespace :bunko do
  desc "Set up Bunko by creating PostTypes from configuration"
  task setup: :environment do
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

    created_count = 0
    existing_count = 0

    post_types.each do |pt_config|
      post_type = PostType.find_by(slug: pt_config[:slug])

      if post_type
        existing_count += 1
        puts "  ✓ PostType already exists: #{pt_config[:name]} (#{pt_config[:slug]})"
      else
        PostType.create!(
          name: pt_config[:name],
          slug: pt_config[:slug]
        )
        created_count += 1
        puts "  ✓ Created PostType: #{pt_config[:name]} (#{pt_config[:slug]})"
      end
    end

    puts ""
    puts "Setup complete!"
    puts "  Created: #{created_count} post type(s)" if created_count > 0
    puts "  Already existed: #{existing_count} post type(s)" if existing_count > 0
    puts ""

    if created_count > 0
      puts "Next steps:"
      puts "  1. Create your first post in the Rails console or admin panel"
      puts "  2. Visit your collections:"
      post_types.each do |pt|
        puts "     http://localhost:3000/#{pt[:slug]}"
      end
    end
  end
end
