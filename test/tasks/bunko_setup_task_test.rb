# frozen_string_literal: true

require_relative "../test_helper"
require "rake"
require "fileutils"

class BunkoSetupTaskTest < Minitest::Test
  def setup
    # Clean database before each test
    PostType.delete_all
    Post.delete_all

    # Set up a temporary directory for test files
    @destination = File.expand_path("../../tmp/rake_test", __dir__)
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
    FileUtils.mkdir_p(File.join(@destination, "config"))
    FileUtils.mkdir_p(File.join(@destination, "app/controllers"))
    FileUtils.mkdir_p(File.join(@destination, "app/models"))
    FileUtils.mkdir_p(File.join(@destination, "db"))

    # Create a basic routes.rb file
    File.write(File.join(@destination, "config/routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY

    # Mock Rails.root to point to our temp directory
    @original_root = Rails.root
    destination = @destination
    Rails.singleton_class.class_eval do
      define_method(:root) { Pathname.new(destination) }
    end

    # Create PostType model in temp location (needed for the task)
    File.write(File.join(@destination, "app/models/post_type.rb"), <<~RUBY)
      class PostType < ApplicationRecord
      end
    RUBY

    # Load Rails rake tasks and our bunko tasks
    Dummy::Application.load_tasks if Rake::Task.tasks.empty?
  end

  def teardown
    # Restore Rails.root
    original_root = @original_root
    Rails.singleton_class.class_eval do
      define_method(:root) { original_root }
    end

    # Clean up temp directory
    FileUtils.rm_rf(@destination) if File.exist?(@destination)

    # Clean up database
    PostType.delete_all
    Post.delete_all

    # Reset configuration to default (empty - must be configured)
    Bunko.configuration.post_types = []
  end

  def test_setup_creates_post_types_in_database
    # Configure with test post types
    Bunko.configure do |config|
      config.post_types = [
        {name: "Blog", slug: "blog"},
        {name: "Docs", slug: "docs"}
      ]
    end

    # Run the task
    run_rake_task("bunko:setup")

    # Verify PostTypes were created
    assert_equal 2, PostType.count
    assert PostType.find_by(slug: "blog")
    assert PostType.find_by(slug: "docs")
  end

  def test_setup_generates_controllers_for_each_post_type
    Bunko.configure do |config|
      config.post_types = [
        {name: "Blog", slug: "blog"},
        {name: "Docs", slug: "docs"}
      ]
    end

    run_rake_task("bunko:setup")

    # Verify controllers were created
    assert File.exist?(File.join(@destination, "app/controllers/blog_controller.rb"))
    assert File.exist?(File.join(@destination, "app/controllers/docs_controller.rb"))

    # Verify controller content
    blog_controller = File.read(File.join(@destination, "app/controllers/blog_controller.rb"))
    assert_match(/class BlogController < ApplicationController/, blog_controller)
    assert_match(/bunko_collection :blog/, blog_controller)
  end

  def test_setup_generates_views_for_each_post_type
    Bunko.configure do |config|
      config.post_types = [{name: "Blog", slug: "blog"}]
    end

    run_rake_task("bunko:setup")

    # Verify views were created
    assert File.exist?(File.join(@destination, "app/views/blog/index.html.erb"))
    assert File.exist?(File.join(@destination, "app/views/blog/show.html.erb"))

    # Verify view content
    index_view = File.read(File.join(@destination, "app/views/blog/index.html.erb"))
    assert_match(/class="blog-index"/, index_view)
    assert_match(/blog_path/, index_view)

    show_view = File.read(File.join(@destination, "app/views/blog/show.html.erb"))
    assert_match(/blog_index_path/, show_view)
  end

  def test_setup_adds_routes_for_each_post_type
    Bunko.configure do |config|
      config.post_types = [
        {name: "Blog", slug: "blog"},
        {name: "Docs", slug: "docs"}
      ]
    end

    run_rake_task("bunko:setup")

    # Verify routes were added
    routes_content = File.read(File.join(@destination, "config/routes.rb"))
    assert_match(/resources :blog, only: \[:index, :show\], param: :slug/, routes_content)
    assert_match(/resources :docs, only: \[:index, :show\], param: :slug/, routes_content)
  end

  def test_setup_with_specific_slug_only_sets_up_that_slug
    Bunko.configure do |config|
      config.post_types = [
        {name: "Blog", slug: "blog"},
        {name: "Docs", slug: "docs"},
        {name: "Changelog", slug: "changelog"}
      ]
    end

    # Run setup for just "docs"
    run_rake_task("bunko:setup", "docs")

    # Verify only docs PostType was created
    assert_equal 1, PostType.count
    assert PostType.find_by(slug: "docs")
    assert_nil PostType.find_by(slug: "blog")
    assert_nil PostType.find_by(slug: "changelog")

    # Verify only docs controller was created
    assert File.exist?(File.join(@destination, "app/controllers/docs_controller.rb"))
    refute File.exist?(File.join(@destination, "app/controllers/blog_controller.rb"))
    refute File.exist?(File.join(@destination, "app/controllers/changelog_controller.rb"))
  end

  def test_setup_is_idempotent_for_post_types
    Bunko.configure do |config|
      config.post_types = [{name: "Blog", slug: "blog"}]
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    run_rake_task("bunko:setup")

    # Should still only have one PostType
    assert_equal 1, PostType.count
  end

  def test_setup_is_idempotent_for_controllers
    Bunko.configure do |config|
      config.post_types = [{name: "Blog", slug: "blog"}]
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    first_controller_content = File.read(File.join(@destination, "app/controllers/blog_controller.rb"))

    run_rake_task("bunko:setup")
    second_controller_content = File.read(File.join(@destination, "app/controllers/blog_controller.rb"))

    # Controller should be identical (not duplicated)
    assert_equal first_controller_content, second_controller_content
  end

  def test_setup_is_idempotent_for_routes
    Bunko.configure do |config|
      config.post_types = [{name: "Blog", slug: "blog"}]
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    run_rake_task("bunko:setup")

    routes_content = File.read(File.join(@destination, "config/routes.rb"))

    # Should only have one route entry (not duplicated)
    assert_equal 1, routes_content.scan("resources :blog").count
  end

  def test_setup_with_invalid_slug_exits_gracefully
    Bunko.configure do |config|
      config.post_types = [{name: "Blog", slug: "blog"}]
    end

    # This should exit with an error message
    # We'll capture the output and verify it contains helpful information
    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:setup", "nonexistent")
      end
    end

    assert_match(/PostType with slug 'nonexistent' not found/, output.join)
    assert_match(/Available slugs: blog/, output.join)
  end

  def test_setup_with_empty_config_exits_gracefully
    Bunko.configure do |config|
      config.post_types = []
    end

    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:setup")
      end
    end

    assert_match(/No post types configured/, output.join)
  end

  private

  def run_rake_task(task_name, *args)
    task = Rake::Task[task_name]
    task.reenable # Allow the task to be run multiple times in tests
    task.invoke(*args)
  end
end
