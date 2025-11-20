# frozen_string_literal: true

require_relative "../test_helper"
require "rake"
require "fileutils"

# Stub Avo module so tests can run without Avo gem installed
module Avo
  class BaseResource; end

  class BaseAction; end

  module Filters
    class SelectFilter; end
  end

  module Actions; end

  module Resources; end
end

# Prepend a module to Kernel to stub require "avo"
module AvoRequireStub
  def require(name)
    return true if name == "avo"
    super
  end
end
Kernel.prepend(AvoRequireStub)

class BunkoAvoTaskTest < Minitest::Test
  def setup
    # Reset Bunko configuration before each test
    Bunko.reset_configuration!

    # Clean database before each test
    Post.delete_all
    PostType.delete_all

    # Set up a temporary directory for test files
    @destination = File.expand_path("../../tmp/avo_rake_test", __dir__)
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
    FileUtils.mkdir_p(File.join(@destination, "config/initializers"))
    FileUtils.mkdir_p(File.join(@destination, "app/avo"))

    # Create Avo initializer (simulates Avo being installed)
    File.write(File.join(@destination, "config/initializers/avo.rb"), <<~RUBY)
      Avo.configure do |config|
        config.root_path = "/avo"
      end
    RUBY

    # Mock Rails.root to point to our temp directory
    @original_root = Rails.root
    destination = @destination
    Rails.singleton_class.class_eval do
      define_method(:root) { Pathname.new(destination) }
    end

    # Configure Bunko with test post types
    Bunko.configure do |config|
      config.post_type "blog"
      config.post_type "docs"
    end

    # Load Rails rake tasks and our bunko tasks
    Dummy::Application.load_tasks if Rake::Task.tasks.empty?

    # Always force reload of bunko:avo:install task to pick up code changes
    if Rake::Task.task_defined?("bunko:avo:install")
      Rake::Task["bunko:avo:install"].clear
    end
    load File.expand_path("../../lib/tasks/bunko/avo.rake", __dir__)
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
    Post.delete_all
    PostType.delete_all

    # Reset configuration
    Bunko.configuration.post_types = []
    Bunko.configuration.collections = []
  end

  def test_avo_install_creates_post_resource
    run_rake_task("bunko:avo:install")

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    assert File.exist?(resource_file), "Post resource should be created"

    content = File.read(resource_file)
    assert_match(/class Avo::Resources::Post < Avo::BaseResource/, content)
    assert_match(/field :title/, content)
    assert_match(/field :content/, content)
    assert_match(/field :status/, content)
    assert_match(/field :published_at/, content)
  end

  def test_avo_install_creates_post_type_filter
    run_rake_task("bunko:avo:install")

    filter_file = File.join(@destination, "app/avo/filters/post_type_filter.rb")
    assert File.exist?(filter_file), "Post type filter should be created"

    content = File.read(filter_file)
    assert_match(/class Avo::Filters::PostTypeFilter < Avo::Filters::SelectFilter/, content)
    assert_match(/def apply\(request, query, value\)/, content)
    assert_match(/post_type = PostType\.find_by\(name: value\)/, content)
    assert_match(/query\.by_post_type\(post_type\)/, content)
  end

  def test_avo_install_creates_publish_action
    run_rake_task("bunko:avo:install")

    action_file = File.join(@destination, "app/avo/actions/publish_post.rb")
    assert File.exist?(action_file), "Publish action should be created"

    content = File.read(action_file)
    assert_match(/class Avo::Actions::PublishPost < Avo::BaseAction/, content)
    assert_match(/post\.update\(status: "published"\)/, content)
    assert_match(/published_at is auto-set by Bunko callback/, content)
  end

  def test_avo_install_creates_unpublish_action
    run_rake_task("bunko:avo:install")

    action_file = File.join(@destination, "app/avo/actions/unpublish_post.rb")
    assert File.exist?(action_file), "Unpublish action should be created"

    content = File.read(action_file)
    assert_match(/class Avo::Actions::UnpublishPost < Avo::BaseAction/, content)
    assert_match(/post\.update\(status: "draft"\)/, content)
    assert_match(/published_at is preserved/, content)
  end

  def test_avo_install_with_markdown_editor
    with_env("EDITOR" => "markdown") do
      run_rake_task("bunko:avo:install")
    end

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)
    assert_match(/field :content, as: :markdown/, content)
  end

  def test_avo_install_with_rhino_editor
    with_env("EDITOR" => "rhino") do
      run_rake_task("bunko:avo:install")
    end

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)
    assert_match(/field :content, as: :rhino/, content)
  end

  def test_avo_install_with_tiptap_editor
    with_env("EDITOR" => "tiptap") do
      run_rake_task("bunko:avo:install")
    end

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)
    assert_match(/field :content, as: :tiptap/, content)
  end

  def test_avo_install_with_trix_editor
    with_env("EDITOR" => "trix") do
      run_rake_task("bunko:avo:install")
    end

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)
    assert_match(/field :content, as: :trix/, content)
  end

  def test_avo_install_with_textarea_editor
    with_env("EDITOR" => "textarea") do
      run_rake_task("bunko:avo:install")
    end

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)
    assert_match(/field :content, as: :textarea/, content)
  end

  def test_avo_install_includes_configured_post_types_in_filter
    run_rake_task("bunko:avo:install")

    filter_file = File.join(@destination, "app/avo/filters/post_type_filter.rb")
    content = File.read(filter_file)
    assert_match(/"Blog" => "blog"/, content)
    assert_match(/"Docs" => "docs"/, content)
  end

  def test_avo_install_idempotency_resource
    # First run - creates files
    run_rake_task("bunko:avo:install")
    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    original_content = File.read(resource_file)

    # Modify the file
    File.write(resource_file, "# Custom changes\n" + original_content)

    # Second run - should skip
    output = capture_io { run_rake_task("bunko:avo:install") }

    # Verify file was not overwritten
    modified_content = File.read(resource_file)
    assert_match(/# Custom changes/, modified_content)
    assert_match(/already exists \(skipped\)/, output.join)
  end

  def test_avo_install_idempotency_filter
    # First run
    run_rake_task("bunko:avo:install")
    filter_file = File.join(@destination, "app/avo/filters/post_type_filter.rb")
    original_content = File.read(filter_file)

    # Modify the file
    File.write(filter_file, "# Custom filter\n" + original_content)

    # Second run - should skip
    output = capture_io { run_rake_task("bunko:avo:install") }

    modified_content = File.read(filter_file)
    assert_match(/# Custom filter/, modified_content)
    assert_match(/already exists \(skipped\)/, output.join)
  end

  def test_avo_install_idempotency_actions
    # First run
    run_rake_task("bunko:avo:install")
    publish_file = File.join(@destination, "app/avo/actions/publish_post.rb")
    unpublish_file = File.join(@destination, "app/avo/actions/unpublish_post.rb")

    publish_content = File.read(publish_file)
    unpublish_content = File.read(unpublish_file)

    # Modify the files
    File.write(publish_file, "# Custom publish\n" + publish_content)
    File.write(unpublish_file, "# Custom unpublish\n" + unpublish_content)

    # Second run - should skip
    output = capture_io { run_rake_task("bunko:avo:install") }

    assert_match(/# Custom publish/, File.read(publish_file))
    assert_match(/# Custom unpublish/, File.read(unpublish_file))
    assert_match(/already exists \(skipped\)/, output.join)
  end

  def test_avo_install_fails_without_avo_initializer
    # Remove Avo initializer (simulates Avo gem installed but not initialized)
    FileUtils.rm(File.join(@destination, "config/initializers/avo.rb"))

    error = assert_raises(SystemExit) do
      capture_io { run_rake_task("bunko:avo:install") }
    end

    assert_equal 1, error.status
  end

  def test_post_type_filter_handles_blank_value
    run_rake_task("bunko:avo:install")

    filter_file = File.join(@destination, "app/avo/filters/post_type_filter.rb")
    content = File.read(filter_file)

    # Verify early return for blank value
    assert_match(/return query if value\.blank\?/, content)
  end

  def test_post_type_filter_handles_nonexistent_post_type
    run_rake_task("bunko:avo:install")

    filter_file = File.join(@destination, "app/avo/filters/post_type_filter.rb")
    content = File.read(filter_file)

    # Verify early return for nil post_type
    assert_match(/return query if post_type\.nil\?/, content)
  end

  def test_avo_install_resource_uses_record_not_post
    run_rake_task("bunko:avo:install")

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)

    # Verify it uses 'record' for reading_time_text
    assert_match(/record\.reading_time_text if record\.word_count\.present\?/, content)
    refute_match(/post\.reading_time_text/, content)
  end

  def test_avo_install_includes_filters_in_resource
    run_rake_task("bunko:avo:install")

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)

    assert_match(/def filters/, content)
    assert_match(/filter Avo::Filters::PostTypeFilter/, content)
  end

  def test_avo_install_includes_actions_in_resource
    run_rake_task("bunko:avo:install")

    resource_file = File.join(@destination, "app/avo/resources/post.rb")
    content = File.read(resource_file)

    assert_match(/def actions/, content)
    assert_match(/action Avo::Actions::PublishPost/, content)
    assert_match(/action Avo::Actions::UnpublishPost/, content)
  end

  private

  def run_rake_task(task_name)
    task = Rake::Task[task_name]
    task.reenable # Allow the task to be run multiple times in tests
    task.invoke
  end

  def with_env(env_vars)
    original_values = {}
    env_vars.each do |key, value|
      original_values[key] = ENV[key]
      ENV[key] = value
    end

    yield
  ensure
    original_values.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
