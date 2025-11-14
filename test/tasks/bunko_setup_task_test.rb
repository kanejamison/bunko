# frozen_string_literal: true

require_relative "../test_helper"
require "rake"
require "fileutils"

class BunkoSetupTaskTest < Minitest::Test
  def setup
    # Reset Bunko configuration before each test
    Bunko.reset_configuration!

    # Clean database before each test (Post first due to foreign key constraints)
    Post.delete_all
    PostType.delete_all

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

    # Always force reload of bunko tasks to pick up code changes
    ["bunko:setup", "bunko:add"].each do |task_name|
      if Rake::Task.task_defined?(task_name)
        Rake::Task[task_name].clear
      end
    end
    load File.expand_path("../../lib/tasks/bunko/setup.rake", __dir__)
    load File.expand_path("../../lib/tasks/bunko/add.rake", __dir__)
  end

  def teardown
    # Restore Rails.root
    original_root = @original_root
    Rails.singleton_class.class_eval do
      define_method(:root) { original_root }
    end

    # Clean up temp directory
    FileUtils.rm_rf(@destination) if File.exist?(@destination)

    # Clean up database (Post first due to foreign key constraints)
    Post.delete_all
    PostType.delete_all

    # Reset configuration to default (empty - must be configured)
    Bunko.configuration.post_types = []
    Bunko.configuration.collections = []
    Bunko.configuration.allow_static_pages = true  # Reset to default
  end

  def test_setup_creates_post_types_in_database
    # Configure with test post types
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    # Run the task
    run_rake_task("bunko:setup")

    # Verify PostTypes were created (including default "pages" PostType)
    assert_equal 3, PostType.count
    assert PostType.find_by(name: "blog")
    assert PostType.find_by(name: "docs")
    assert PostType.find_by(name: "pages")
  end

  def test_setup_generates_controllers_for_each_post_type
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
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
      config.post_type "blog"
    end

    run_rake_task("bunko:setup")

    # Verify views were created
    assert File.exist?(File.join(@destination, "app/views/blog/index.html.erb"))
    assert File.exist?(File.join(@destination, "app/views/blog/show.html.erb"))

    # Verify view content
    index_view = File.read(File.join(@destination, "app/views/blog/index.html.erb"))
    assert_match(/class="container blog-index"/, index_view)
    assert_match(/blog_index_path/, index_view) # Pagination uses blog_index_path (singular resource)
    assert_match(/blog_path/, index_view) # Show links use blog_path

    show_view = File.read(File.join(@destination, "app/views/blog/show.html.erb"))
    assert_match(/blog_index_path/, show_view) # Back link uses blog_index_path (singular resource)
  end

  def test_setup_adds_routes_for_each_post_type
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    run_rake_task("bunko:setup")

    # Verify routes were added using bunko_collection
    routes_content = File.read(File.join(@destination, "config/routes.rb"))
    assert_match(/bunko_collection :blog/, routes_content)
    assert_match(/bunko_collection :docs/, routes_content)
  end

  def test_add_post_type_adds_single_post_type
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
      config.post_type "changelog"
    end

    # Add just "docs" using the add task
    run_rake_task("bunko:add", "docs")

    # Verify only docs PostType was created
    assert_equal 1, PostType.count
    assert PostType.find_by(name: "docs")
    assert_nil PostType.find_by(name: "blog")
    assert_nil PostType.find_by(name: "changelog")

    # Verify only docs controller was created
    assert File.exist?(File.join(@destination, "app/controllers/docs_controller.rb"))
    refute File.exist?(File.join(@destination, "app/controllers/blog_controller.rb"))
    refute File.exist?(File.join(@destination, "app/controllers/changelog_controller.rb"))
  end

  def test_setup_is_idempotent_for_post_types
    Bunko.configure do |config|
      config.post_type "blog"
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    run_rake_task("bunko:setup")

    # Should still only have two PostTypes (blog + pages)
    assert_equal 2, PostType.count
  end

  def test_setup_is_idempotent_for_controllers
    Bunko.configure do |config|
      config.post_type "blog"
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
      config.post_type "blog"
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    run_rake_task("bunko:setup")

    routes_content = File.read(File.join(@destination, "config/routes.rb"))

    # Should only have one route entry (not duplicated)
    assert_equal 1, routes_content.scan("bunko_collection :blog").count
  end

  def test_add_with_invalid_name_exits_gracefully
    Bunko.configure do |config|
      config.post_type "blog"
    end

    # This should exit with an error message
    # We'll capture the output and verify it contains helpful information
    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:add", "nonexistent")
      end
    end

    assert_match(/'nonexistent' not found in configuration/, output.join)
    assert_match(/Available PostTypes: blog/, output.join)
  end

  def test_setup_with_empty_config_exits_gracefully
    Bunko.configure do |config|
      config.post_types = []
      config.allow_static_pages = false
    end

    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:setup")
      end
    end

    assert_match(/No post types configured and static pages are disabled/, output.join)
  end

  def test_setup_generates_controllers_for_collections
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    run_rake_task("bunko:setup")

    # Verify collection controller was created
    assert File.exist?(File.join(@destination, "app/controllers/resources_controller.rb"))

    # Verify controller content
    resources_controller = File.read(File.join(@destination, "app/controllers/resources_controller.rb"))
    assert_match(/class ResourcesController < ApplicationController/, resources_controller)
    assert_match(/bunko_collection :resources/, resources_controller)
  end

  def test_setup_generates_views_for_collections
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    run_rake_task("bunko:setup")

    # Verify views were created (Collections only get index view, not show view)
    assert File.exist?(File.join(@destination, "app/views/resources/index.html.erb"))
    refute File.exist?(File.join(@destination, "app/views/resources/show.html.erb")), "Collections should not have show views"
  end

  def test_setup_adds_routes_for_collections
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    run_rake_task("bunko:setup")

    # Verify routes were added
    routes_content = File.read(File.join(@destination, "config/routes.rb"))
    assert_match(/bunko_collection :resources/, routes_content)
  end

  def test_setup_generates_shared_nav_partial
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    run_rake_task("bunko:setup")

    # Verify nav partial was created
    nav_file = File.join(@destination, "app/views/shared/_bunko_nav.html.erb")
    assert File.exist?(nav_file)

    # Verify nav content
    nav_content = File.read(nav_file)
    assert_match(/link_to "Home", root_path/, nav_content)
  end

  def test_nav_partial_contains_post_type_links_in_order
    Bunko.configure do |config|
      config.post_type "blog" do |type|
        type.title = "Blog"
      end
      config.post_type "docs" do |type|
        type.title = "Documentation"
      end
      config.post_type "changelog" do |type|
        type.title = "Changelog"
      end
    end

    run_rake_task("bunko:setup")

    nav_content = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))

    # Verify all post type links are present
    assert_match(/link_to "Blog", blog_index_path/, nav_content)
    assert_match(/link_to "Documentation", docs_path/, nav_content)
    assert_match(/link_to "Changelog", changelog_index_path/, nav_content)

    # Verify order (Blog should come before Docs, Docs before Changelog)
    blog_position = nav_content.index('"Blog"')
    docs_position = nav_content.index('"Documentation"')
    changelog_position = nav_content.index('"Changelog"')

    refute_nil blog_position, "Blog link should be present in nav"
    refute_nil docs_position, "Documentation link should be present in nav"
    refute_nil changelog_position, "Changelog link should be present in nav"

    assert blog_position < docs_position, "Blog link should come before Docs link"
    assert docs_position < changelog_position, "Docs link should come before Changelog link"
  end

  def test_nav_partial_contains_collection_links
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    run_rake_task("bunko:setup")

    nav_content = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))

    # Verify collection link is present
    assert_match(/link_to "Resources", resources_path/, nav_content)
  end

  def test_nav_partial_lists_post_types_before_collections
    Bunko.configure do |config|
      config.post_type "articles" do |type|
        type.title = "Articles"
      end
      config.post_type "videos" do |type|
        type.title = "Videos"
      end
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    run_rake_task("bunko:setup")

    nav_content = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))

    # Debug: print nav content to see what's actually generated
    # puts "\n=== Nav Content ===\n#{nav_content}\n==================\n"

    # Verify PostTypes come before Collections
    articles_position = nav_content.index('"Articles"')
    resources_position = nav_content.index('"Resources"')

    refute_nil articles_position, "Articles link should be present in nav. Nav content: #{nav_content}"
    refute_nil resources_position, "Resources link should be present in nav. Nav content: #{nav_content}"
    assert articles_position < resources_position, "PostType links should come before Collection links"
  end

  def test_setup_is_idempotent_for_nav_partial
    Bunko.configure do |config|
      config.post_type "blog"
    end

    # Run setup twice
    run_rake_task("bunko:setup")
    first_nav_content = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))

    run_rake_task("bunko:setup")
    second_nav_content = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))

    # Nav partial should be identical (not duplicated)
    assert_equal first_nav_content, second_nav_content
  end

  def test_generated_views_include_nav_partial
    Bunko.configure do |config|
      config.post_type "blog"
    end

    run_rake_task("bunko:setup")

    # Verify index view includes nav partial
    index_view = File.read(File.join(@destination, "app/views/blog/index.html.erb"))
    assert_match(/render "shared\/bunko_nav"/, index_view)

    # Verify show view includes nav partial
    show_view = File.read(File.join(@destination, "app/views/blog/show.html.erb"))
    assert_match(/render "shared\/bunko_nav"/, show_view)
  end

  def test_add_collection_adds_single_collection
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    # Add just the collection
    run_rake_task("bunko:add", "resources")

    # Verify controller was created
    assert File.exist?(File.join(@destination, "app/controllers/resources_controller.rb"))

    # Verify views were created (Collections only get index view, not show view)
    assert File.exist?(File.join(@destination, "app/views/resources/index.html.erb"))
    refute File.exist?(File.join(@destination, "app/views/resources/show.html.erb")), "Collections should not have show views"

    # Verify route was added
    routes_content = File.read(File.join(@destination, "config/routes.rb"))
    assert_match(/bunko_collection :resources/, routes_content)
  end

  def test_add_regenerates_nav_for_post_type
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    # Run setup for initial nav
    run_rake_task("bunko:setup")

    nav_content_before = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))
    assert_match(/"Blog"/, nav_content_before)
    assert_match(/"Docs"/, nav_content_before)

    # Add a new post type
    Bunko.configuration.post_type "changelog"

    run_rake_task("bunko:add", "changelog")

    # Nav should be regenerated with new post type
    nav_content_after = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))
    assert_match(/"Blog"/, nav_content_after)
    assert_match(/"Docs"/, nav_content_after)
    assert_match(/"Changelog"/, nav_content_after)
  end

  def test_add_regenerates_nav_for_collection
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
    end

    # Run setup for initial nav
    run_rake_task("bunko:setup")

    nav_content_before = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))
    refute_match(/"Resources"/, nav_content_before)

    # Add a new collection
    Bunko.configuration.collection "resources" do |c|
      c.post_types = ["articles", "videos"]
    end

    run_rake_task("bunko:add", "resources")

    # Nav should now include the new collection
    nav_content_after = File.read(File.join(@destination, "app/views/shared/_bunko_nav.html.erb"))
    assert_match(/"Resources"/, nav_content_after)
  end

  def test_unified_add_command_works_for_post_type
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    # Use unified add command for a post type
    run_rake_task("bunko:add", "blog")

    # Verify PostType was created
    assert_equal 1, PostType.count
    assert PostType.find_by(name: "blog")

    # Verify controller was created
    assert File.exist?(File.join(@destination, "app/controllers/blog_controller.rb"))
  end

  def test_unified_add_command_works_for_collection
    Bunko.configure do |config|
      config.post_type "articles"
      config.post_type "videos"
      config.collection "resources" do |c|
        c.post_types = ["articles", "videos"]
      end
    end

    # Use unified add command for a collection
    run_rake_task("bunko:add", "resources")

    # Verify controller was created
    assert File.exist?(File.join(@destination, "app/controllers/resources_controller.rb"))

    # Verify views were created
    assert File.exist?(File.join(@destination, "app/views/resources/index.html.erb"))
  end

  def test_unified_add_command_with_invalid_name_exits_gracefully
    Bunko.configure do |config|
      config.post_type "blog"
      config.collection "resources" do |c|
        c.post_types = ["blog"]
      end
    end

    output = capture_io do
      assert_raises(SystemExit) do
        run_rake_task("bunko:add", "nonexistent")
      end
    end

    assert_match(/'nonexistent' not found in configuration/, output.join)
    assert_match(/Available PostTypes: blog/, output.join)
    assert_match(/Available Collections: resources/, output.join)
  end

  private

  def run_rake_task(task_name, *args)
    task = Rake::Task[task_name]
    task.reenable # Allow the task to be run multiple times in tests
    task.invoke(*args)
  end
end
