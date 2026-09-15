# frozen_string_literal: true

require "fileutils"
require_relative "helpers"

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
    collection_config = Bunko.configuration.collections.find { |c| c[:name] == name }

    unless pt_config || collection_config
      # Not found in either
      puts "⚠️  '#{name}' not found in configuration"
      puts ""

      available_post_types = Bunko.configuration.post_types.map { |pt| pt[:name] }
      available_collections = Bunko.configuration.collections.map { |c| c[:name] }

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
      puts "   config.collection \"#{name}\" do |c|"
      puts "     c.post_types = [...]"
      puts "   end"
      exit 1
    end

    # Step 1: If it's a PostType, create DB entry
    if pt_config
      Bunko::RakeHelpers.create_post_type_in_database(name, pt_config[:title])
    end

    # Step 2: Always generate artifacts (for both PostTypes and Collections)
    is_collection = collection_config.present?
    Bunko::RakeHelpers.generate_artifacts(name, format: format, is_collection: is_collection)

    # Step 3: Add to nav
    if pt_config
      Bunko::RakeHelpers.add_to_nav(name, title: pt_config[:title])
    else
      Bunko::RakeHelpers.add_to_nav(name, title: collection_config[:title])
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
end
