# frozen_string_literal: true

namespace :bunko do
  desc "Generate sample posts for all configured post types (requires faker gem)"
  task sample_data: :environment do
    # Warn if running in production
    if Rails.env.production?
      puts ""
      puts "⚠️  WARNING: You're about to generate sample data in PRODUCTION"
      puts "    Press Ctrl+C to cancel, or Enter to continue..."
      $stdin.gets
      puts ""
    end

    # Check for Faker
    begin
      require "faker"
    rescue LoadError
      puts "⚠️  Faker gem required. Add to your Gemfile:"
      puts "    gem 'faker'  # (or group: :development for dev-only)"
      puts ""
      exit 1
    end

    # Parse configuration from ENV
    posts_per_type = ENV.fetch("COUNT", ENV.fetch("POSTS_PER_TYPE", "20")).to_i
    min_words = ENV.fetch("MIN_WORDS", "200").to_i
    max_words = ENV.fetch("MAX_WORDS", "2000").to_i
    clear_existing = ENV.fetch("CLEAR", "false").downcase == "true"

    puts "Bunko Sample Data Generator"
    puts "=" * 79
    puts "Configuration:"
    puts "  Posts per type: #{posts_per_type}"
    puts "  Word range: #{min_words}-#{max_words} words"
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
          Faker::Time.between(from: 2.years.ago, to: Time.current)
        else
          Faker::Time.between(from: Time.current, to: 3.months.from_now)
        end

        # Generate title and content based on post type
        title = generate_title_for(post_type.name)
        target_words = rand(min_words..max_words)
        content = generate_content_for(post_type.name, target_words)

        # Create unique slug
        base_slug = title.parameterize
        slug = base_slug
        counter = 1

        while Post.exists?(post_type: post_type, slug: slug)
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end

        # Create meta description
        meta_description = Faker::Lorem.sentence(word_count: rand(15..25)).chomp(".")

        # Create post
        Post.create!(
          post_type: post_type,
          title: title,
          slug: slug,
          content: content,
          meta_description: meta_description,
          title_tag: "#{title} | #{Faker::Company.name}",
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
    puts "  rake bunko:sample_data                           # 20 posts per type"
    puts "  rake bunko:sample_data COUNT=50                  # 50 posts per type"
    puts "  rake bunko:sample_data MIN_WORDS=500 MAX_WORDS=1500"
    puts "  rake bunko:sample_data CLEAR=true                # Clear existing first"
    puts ""
  end

  # Helper: Generate titles based on post type patterns
  def generate_title_for(post_type_name)
    case post_type_name
    when /blog/i
      Faker::Lorem.sentence(word_count: rand(3..10)).chomp(".")
    when /doc/i
      "#{Faker::Hacker.verb.capitalize} #{Faker::Hacker.noun} with #{Faker::Hacker.adjective} #{Faker::Hacker.noun}"
    when /changelog|release|version/i
      "Version #{Faker::App.semantic_version} - #{Faker::Hacker.verb.capitalize} #{Faker::Hacker.noun}"
    when /case.?stud|success|customer/i
      "How #{Faker::Company.name} #{Faker::Company.bs.capitalize}"
    when /news|announcement/i
      "#{Faker::Company.buzzword.capitalize} #{Faker::Lorem.sentence(word_count: rand(3..6)).chomp(".")}"
    when /tutorial|guide/i
      "A Complete Guide to #{Faker::Hacker.ingverb.capitalize} #{Faker::Hacker.noun}"
    when /api|reference/i
      "#{Faker::Hacker.noun.capitalize} API Reference"
    else
      Faker::Lorem.sentence(word_count: rand(3..10)).chomp(".")
    end
  end

  # Helper: Generate paragraphs of content
  def generate_paragraphs(target_words)
    num_paragraphs = (target_words / 125.0).ceil
    paragraphs = num_paragraphs.times.map do
      Faker::Lorem.paragraph(sentence_count: rand(4..8), supplemental: true, random_sentences_to_add: rand(2..5))
    end
    paragraphs.join("\n\n")
  end

  # Helper: Generate structured content based on post type
  def generate_content_for(post_type_name, target_words)
    case post_type_name
    when /blog/i
      # Blog: Introduction + Body + Conclusion
      [
        generate_paragraphs(target_words * 0.15),
        generate_paragraphs(target_words * 0.70),
        "## Conclusion",
        generate_paragraphs(target_words * 0.15)
      ].join("\n\n")

    when /doc/i
      # Documentation: Overview + Getting Started + Examples + Configuration
      section_words = target_words / 4
      [
        "## Overview",
        generate_paragraphs(section_words),
        "## Getting Started",
        generate_paragraphs(section_words),
        "## Examples",
        "```ruby\n# #{Faker::Hacker.say_something_smart}\n#{Faker::Lorem.word} = #{Faker::Lorem.word.capitalize}.new(#{Faker::Lorem.word}: '#{Faker::Lorem.word}')\n#{Faker::Lorem.word}.#{Faker::Hacker.verb}!\n```",
        generate_paragraphs(section_words * 0.5),
        "## Configuration",
        generate_paragraphs(section_words * 0.5)
      ].join("\n\n")

    when /changelog|release|version/i
      # Changelog: Added + Fixed + Changed + Improved
      num_items = rand(3..6)
      [
        "## Added",
        num_items.times.map { "- #{Faker::Hacker.verb.capitalize} #{Faker::Hacker.adjective} #{Faker::Hacker.noun} functionality" }.join("\n"),
        generate_paragraphs(target_words * 0.2),
        "\n## Fixed",
        num_items.times.map { "- #{Faker::Lorem.sentence}" }.join("\n"),
        generate_paragraphs(target_words * 0.2),
        "\n## Changed",
        num_items.times.map { "- #{Faker::Lorem.sentence}" }.join("\n"),
        generate_paragraphs(target_words * 0.2),
        "\n## Improved",
        num_items.times.map { "- #{Faker::Hacker.verb.capitalize} #{Faker::Hacker.noun} performance" }.join("\n"),
        generate_paragraphs(target_words * 0.2)
      ].join("\n")

    when /case.?stud|success|customer/i
      # Case Study: Challenge + Solution + Results + Conclusion
      section_words = target_words / 4
      [
        "## The Challenge",
        generate_paragraphs(section_words),
        "## The Solution",
        generate_paragraphs(section_words),
        "## The Results",
        "- #{rand(100..500)}% increase in #{Faker::Lorem.word}",
        "- #{rand(50..200)}% improvement in #{Faker::Lorem.word}",
        "- #{rand(20..90)}% reduction in #{Faker::Lorem.word}",
        "- #{Faker::Number.decimal(l_digits: 2)}x faster #{Faker::Lorem.word} processing",
        generate_paragraphs(section_words * 0.5),
        "## Conclusion",
        generate_paragraphs(section_words)
      ].join("\n\n")

    when /tutorial|guide/i
      # Tutorial: Prerequisites + Steps + Troubleshooting
      step_words = target_words / 5
      [
        "## Prerequisites",
        generate_paragraphs(step_words),
        "## Step 1: Setup",
        generate_paragraphs(step_words),
        "## Step 2: Implementation",
        generate_paragraphs(step_words),
        "## Step 3: Testing",
        generate_paragraphs(step_words),
        "## Troubleshooting",
        generate_paragraphs(step_words)
      ].join("\n\n")

    else
      # Default: Long-form content with occasional subheadings
      num_sections = rand(2..4)
      section_words = target_words / num_sections
      sections = []

      num_sections.times do |i|
        if i > 0
          sections << "## #{Faker::Lorem.sentence(word_count: rand(2..4)).chomp(".")}"
        end
        sections << generate_paragraphs(section_words)
      end

      sections.join("\n\n")
    end
  end
end
