# frozen_string_literal: true

require_relative "../test_helper"
require "rake"
require "fileutils"

class BunkoInstallTaskTest < Minitest::Test
  def setup
    # Set up a temporary directory for test files
    @destination = File.expand_path("../../tmp/install_test", __dir__)
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
    FileUtils.mkdir_p(File.join(@destination, "config"))
    FileUtils.mkdir_p(File.join(@destination, "app/models"))
    FileUtils.mkdir_p(File.join(@destination, "db/migrate"))

    # Mock Rails.root to point to our temp directory
    @original_root = Rails.root
    destination = @destination
    Rails.singleton_class.class_eval do
      define_method(:root) { Pathname.new(destination) }
    end

    # Load Rails rake tasks and our bunko tasks
    Dummy::Application.load_tasks if Rake::Task.tasks.empty?

    # Always force reload of bunko:install task to pick up code changes
    if Rake::Task.task_defined?("bunko:install")
      Rake::Task["bunko:install"].clear
      load File.expand_path("../../lib/tasks/bunko/install.rake", __dir__)
    end
  end

  def teardown
    # Restore Rails.root
    original_root = @original_root
    Rails.singleton_class.class_eval do
      define_method(:root) { original_root }
    end

    # Clean up temp directory
    FileUtils.rm_rf(@destination) if File.exist?(@destination)
  end

  def test_install_creates_migrations
    run_rake_task("bunko:install")

    migration_files = Dir.glob(File.join(@destination, "db/migrate/*.rb"))
    assert_equal 2, migration_files.size, "Expected 2 migration files"

    # Check that migrations were created
    assert migration_files.any? { |f| f.include?("create_post_types") }
    assert migration_files.any? { |f| f.include?("create_posts") }
  end

  def test_install_creates_models
    run_rake_task("bunko:install")

    assert File.exist?(File.join(@destination, "app/models/post_type.rb"))
    assert File.exist?(File.join(@destination, "app/models/post.rb"))

    # Check content
    post_content = File.read(File.join(@destination, "app/models/post.rb"))
    assert_match(/acts_as_bunko_post/, post_content)

    post_type_content = File.read(File.join(@destination, "app/models/post_type.rb"))
    assert_match(/acts_as_bunko_post_type/, post_type_content)
  end

  def test_install_creates_initializer
    run_rake_task("bunko:install")

    assert File.exist?(File.join(@destination, "config/initializers/bunko.rb"))

    content = File.read(File.join(@destination, "config/initializers/bunko.rb"))
    assert_match(/Bunko\.configure/, content)
  end

  def test_migration_uses_text_content_by_default
    run_rake_task("bunko:install")

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    assert_match(/t\.text :content/, content)
    refute_match(/t\.jsonb :content/, content)
  end

  def test_migration_uses_jsonb_content_with_env_var
    ENV["JSON_CONTENT"] = "true"
    run_rake_task("bunko:install")
    ENV.delete("JSON_CONTENT")

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    assert_match(/t\.jsonb :content/, content)
    refute_match(/t\.text :content/, content)
  end

  def test_migration_includes_seo_fields_by_default
    run_rake_task("bunko:install")

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    assert_match(/t\.string :title_tag/, content)
    assert_match(/t\.text :meta_description/, content)
  end

  def test_migration_skips_seo_fields_with_env_var
    ENV["SKIP_SEO"] = "true"
    run_rake_task("bunko:install")
    ENV.delete("SKIP_SEO")

    posts_migration = Dir.glob(File.join(@destination, "db/migrate/*_create_posts.rb")).first
    content = File.read(posts_migration)

    refute_match(/t\.string :title_tag/, content)
    refute_match(/t\.text :meta_description/, content)
  end

  def test_install_is_idempotent
    # Run install twice
    run_rake_task("bunko:install")
    run_rake_task("bunko:install")

    # Should still only have 2 migrations
    migration_files = Dir.glob(File.join(@destination, "db/migrate/*.rb"))
    assert_equal 2, migration_files.size
  end

  private

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    capture_io do
      Rake::Task[task_name].invoke
    end
  end
end
