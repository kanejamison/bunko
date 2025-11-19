# frozen_string_literal: true

require_relative "../support/sample_data_generator"
require_relative "helpers"

# Standard static pages to generate
BUNKO_STANDARD_PAGES = [
  {slug: "home", title: "Home"},
  {slug: "about", title: "About"},
  {slug: "contact", title: "Contact"},
  {slug: "faq", title: "FAQ"},
  {slug: "privacy-policy", title: "Privacy Policy"},
  {slug: "cookie-policy", title: "Cookie Policy"},
  {slug: "terms-of-service", title: "Terms of Service"}
].freeze

namespace :bunko do
  include Bunko::RakeHelpers

  desc "Generate sample posts for all configured post types"
  task sample_data: :environment do
    # Warn if running in production
    if Rails.env.production?
      puts ""
      puts "⚠️  WARNING: You're about to generate sample data in PRODUCTION"
      puts "    Press Ctrl+C to cancel, or Enter to continue..."
      $stdin.gets
      puts ""
    end

    # Parse configuration from ENV
    posts_per_type = ENV.fetch("COUNT", ENV.fetch("POSTS_PER_TYPE", "100")).to_i
    min_words = ENV.fetch("MIN_WORDS", "500").to_i
    max_words = ENV.fetch("MAX_WORDS", "2000").to_i
    clear_existing = ENV.fetch("CLEAR", "false").downcase == "true"
    format = ENV.fetch("FORMAT", "html").downcase.to_sym

    # Validate format
    unless Bunko::SampleDataGenerator::FORMATS.include?(format)
      puts "⚠️  Invalid format: #{format}"
      puts "    Valid formats: #{Bunko::SampleDataGenerator::FORMATS.join(", ")}"
      puts ""
      exit 1
    end

    puts "Bunko Sample Data Generator"
    puts "=" * 79
    puts "Configuration:"
    puts "  Posts per type: #{posts_per_type}"
    puts "  Word range: #{min_words}-#{max_words} words"
    puts "  Content format: #{format}"
    puts "  Clear existing: #{clear_existing ? "Yes" : "No"}"
    puts ""

    # Clear existing posts if requested
    if clear_existing
      puts "Clearing existing posts..."
      Post.destroy_all
      puts "✓ Cleared #{Post.count} posts"
      puts ""
    end

    # Get all post types from database (excluding "pages" which are handled separately)
    post_types = PostType.where.not(name: "pages")

    if post_types.empty?
      puts "⚠️  No post types found. Please run 'rails bunko:setup' first."
      exit 1
    end

    puts "Generating posts for #{post_types.size} post types..."
    puts ""

    # Generate posts for each type
    post_types.each do |post_type|
      puts "#{post_type.title} (#{post_type.name}):"
      print "  "

      posts_per_type.times do |i|
        # Create varied dates: 90% past, 10% future
        published_at = if rand < 0.9
          Bunko::SampleDataGenerator.past_date(years_ago: 2)
        else
          Bunko::SampleDataGenerator.future_date(months_ahead: 3)
        end

        # Generate title and content based on post type
        title = Bunko::SampleDataGenerator.title_for(post_type.name)
        target_words = rand(min_words..max_words)
        content = Bunko::SampleDataGenerator.content_for(post_type.name, target_words: target_words, format: format)

        # Create unique slug
        base_slug = title.parameterize
        slug = base_slug
        counter = 1

        while Post.exists?(post_type: post_type, slug: slug)
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end

        # Create meta description
        meta_description = Bunko::SampleDataGenerator.sentence(word_count: rand(15..25)).chomp(".")

        # Create post
        Post.create!(
          post_type: post_type,
          title: title,
          slug: slug,
          content: content,
          meta_description: meta_description,
          title_tag: "#{title} | Sample Site",
          status: "published",
          published_at: published_at
        )

        print "." if (i + 1) % 5 == 0
      end

      puts " ✓"
    end

    puts ""
    puts "=" * 79
    puts "Summary:"
    post_types.each do |post_type|
      count = Post.where(post_type: post_type).count
      future_count = Post.where(post_type: post_type).where("published_at > ?", Time.current).count
      avg_words = Post.where(post_type: post_type).average(:word_count).to_i
      puts "  #{post_type.title}: #{count} posts (#{future_count} scheduled, avg #{avg_words} words)"
    end

    # Show pages summary if they exist
    pages_post_type = PostType.find_by(name: "pages")
    if pages_post_type
      pages_count = Post.where(post_type: pages_post_type).count
      if pages_count > 0
        puts "  Pages: #{pages_count} static page(s)"
      end
    end

    puts "=" * 79
    puts ""

    # Generate static pages if allowed
    if Bunko.configuration.allow_static_pages
      puts "Generating static pages..."
      puts ""

      # Check if pages PostType exists
      pages_post_type = PostType.find_by(name: "pages")

      if pages_post_type.nil?
        puts "⚠️  'pages' PostType not found. Run 'rails bunko:setup' first to enable static pages."
        puts ""
      else
        # Determine which pages to create
        pages_to_create = BUNKO_STANDARD_PAGES.dup

        # Remove home if root route already exists
        if root_route_exists?
          pages_to_create.reject! { |page| page[:slug] == "home" }
          puts "  - Skipping 'home' page (root route already exists)"
        end

        # Get existing page slugs
        existing_slugs = Post.where(post_type: pages_post_type).pluck(:slug)

        # Filter out pages that already exist
        pages_to_create.reject! { |page| existing_slugs.include?(page[:slug]) }

        if pages_to_create.empty?
          puts "  - All standard pages already exist (skipped)"
          puts ""
        else
          # Create the pages
          pages_to_create.each do |page_def|
            # Generate content for the page
            target_words = rand(min_words..max_words)
            content = Bunko::SampleDataGenerator.content_for("pages", target_words: target_words, format: format)

            # Create meta description
            meta_description = Bunko::SampleDataGenerator.sentence(word_count: rand(15..25)).chomp(".")

            # Create the page
            Post.create!(
              post_type: pages_post_type,
              title: page_def[:title],
              slug: page_def[:slug],
              content: content,
              meta_description: meta_description,
              title_tag: "#{page_def[:title]} | Sample Site",
              status: "published",
              published_at: Time.current
            )

            puts "  ✓ Created #{page_def[:title]} page"
          end

          puts ""
          puts "Adding routes for new pages..."

          # Add routes for the created pages
          pages_to_create.each do |page_def|
            # Home gets special treatment with path: "/"
            if page_def[:slug] == "home"
              if add_bunko_page_route(page_def[:slug], path: "/")
                puts "  ✓ Added route: bunko_page :home, path: \"/\""
              else
                puts "  - Route for :home already exists (skipped)"
              end
            elsif add_bunko_page_route(page_def[:slug])
              puts "  ✓ Added route: bunko_page :#{page_def[:slug].tr("-", "_")}"
            else
              puts "  - Route for :#{page_def[:slug].tr("-", "_")} already exists (skipped)"
            end
          end

          puts ""
          puts "Created #{pages_to_create.size} static page(s)."
        end
      end

      puts "=" * 79
      puts ""
    end

    puts "Usage examples:"
    puts "  rake bunko:sample_data                           # 100 posts per type (HTML with images)"
    puts "  rake bunko:sample_data COUNT=50                  # 50 posts per type"
    puts "  rake bunko:sample_data FORMAT=markdown           # Markdown formatted content"
    puts "  rake bunko:sample_data MIN_WORDS=500 MAX_WORDS=1500"
    puts "  rake bunko:sample_data CLEAR=true                # Clear existing first"
    puts ""
  end

  # Helper methods

  def root_route_exists?
    Rails.application.routes.named_routes[:root].present?
  end

  def add_bunko_page_route(slug, path: nil)
    routes_file = Rails.root.join("config/routes.rb")
    routes_content = File.read(routes_file)

    # Build the route line
    route_line = if path
      "  bunko_page :#{slug.tr("-", "_")}, path: \"#{path}\""
    else
      "  bunko_page :#{slug.tr("-", "_")}"
    end

    # Check if this route already exists
    slug_symbol = ":#{slug.tr("-", "_")}"
    if routes_content.match?(/bunko_page\s+#{Regexp.escape(slug_symbol)}/)
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
    true
  end
end
