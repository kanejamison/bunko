# frozen_string_literal: true

require_relative "../support/sample_data_generator"

namespace :bunko do
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
    posts_per_type = ENV.fetch("COUNT", ENV.fetch("POSTS_PER_TYPE", "20")).to_i
    min_words = ENV.fetch("MIN_WORDS", "200").to_i
    max_words = ENV.fetch("MAX_WORDS", "2000").to_i
    clear_existing = ENV.fetch("CLEAR", "false").downcase == "true"
    format = ENV.fetch("FORMAT", "plain").downcase.to_sym

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

    # Get all post types from database
    post_types = PostType.all

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
          title_tag: "#{title} | #{Bunko::SampleDataGenerator.company_name}",
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
    puts "=" * 79
    puts ""
    puts "Usage examples:"
    puts "  rake bunko:sample_data                           # 20 posts per type (plain text)"
    puts "  rake bunko:sample_data COUNT=50                  # 50 posts per type"
    puts "  rake bunko:sample_data FORMAT=markdown           # Markdown formatted content"
    puts "  rake bunko:sample_data FORMAT=html               # HTML formatted content"
    puts "  rake bunko:sample_data MIN_WORDS=500 MAX_WORDS=1500"
    puts "  rake bunko:sample_data CLEAR=true                # Clear existing first"
    puts ""
  end
end
