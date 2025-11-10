# frozen_string_literal: true

require_relative "../test_helper"
require "generators/bunko/install/install_generator"
require "fileutils"

class InstallManualTest < Minitest::Test
  def setup
    @destination = File.expand_path("../../tmp", __dir__)
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
    FileUtils.mkdir_p(File.join(@destination, "config"))
    File.write(File.join(@destination, "config/routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(@destination) if File.exist?(@destination)
  end

  def test_generator_creates_migrations
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_migrations

    migration_files = Dir.glob(File.join(@destination, "db/migrate/*.rb"))
    assert_equal 2, migration_files.size, "Expected 2 migration files"

    # Check that migrations were created
    assert migration_files.any? { |f| f.include?("create_post_types") }
    assert migration_files.any? { |f| f.include?("create_posts") }
  end

  def test_generator_creates_models
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_models

    assert File.exist?(File.join(@destination, "app/models/post_type.rb"))
    assert File.exist?(File.join(@destination, "app/models/post.rb"))

    # Check content
    post_content = File.read(File.join(@destination, "app/models/post.rb"))
    assert_match(/acts_as_bunko_post/, post_content)
  end

  def test_generator_creates_initializer
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_initializer

    assert File.exist?(File.join(@destination, "config/initializers/bunko.rb"))

    content = File.read(File.join(@destination, "config/initializers/bunko.rb"))
    assert_match(/Bunko\.configure/, content)
  end

  def test_migration_uses_text_content_by_default
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_migrations

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    assert_match(/t\.text :content/, content)
    refute_match(/t\.jsonb :content/, content)
  end

  def test_migration_uses_jsonb_content_with_flag
    generator = Bunko::Generators::InstallGenerator.new([], {json_content: true}, destination_root: @destination)
    generator.create_migrations

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    assert_match(/t\.jsonb :content/, content)
    refute_match(/t\.text :content/, content)
  end
end
