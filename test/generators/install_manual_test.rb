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

  def test_generator_creates_controller
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_controller

    assert File.exist?(File.join(@destination, "app/controllers/blog_controller.rb"))

    content = File.read(File.join(@destination, "app/controllers/blog_controller.rb"))
    assert_match(/bunko_collection :blog/, content)
  end

  def test_generator_creates_views
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_views

    assert File.exist?(File.join(@destination, "app/views/blog/index.html.erb"))
    assert File.exist?(File.join(@destination, "app/views/blog/show.html.erb"))
  end

  def test_generator_skips_views_with_option
    generator = Bunko::Generators::InstallGenerator.new([], {skip_views: true}, destination_root: @destination)
    generator.create_views

    refute File.exist?(File.join(@destination, "app/views/blog/index.html.erb"))
    refute File.exist?(File.join(@destination, "app/views/blog/show.html.erb"))
  end

  def test_generator_creates_initializer
    generator = Bunko::Generators::InstallGenerator.new([], {}, destination_root: @destination)
    generator.create_initializer

    assert File.exist?(File.join(@destination, "config/initializers/bunko.rb"))

    content = File.read(File.join(@destination, "config/initializers/bunko.rb"))
    assert_match(/Bunko\.configure/, content)
  end
end
