# frozen_string_literal: true

begin
  require "brakeman"

  namespace :brakeman do
    desc "Run Brakeman security scan against test dummy-brakeman app"
    task :scan do
      dummy_path = File.expand_path("../../test/dummy-brakeman", __dir__)
      gemfile_path = File.join(dummy_path, "Gemfile")

      # Determine Rails version to test (from ENV or default)
      rails_version = ENV["RAILS_VERSION"] || ">= 8.0"

      puts "Setting up test/dummy-brakeman app for Brakeman..."
      puts "Rails version: #{rails_version}"

      # Clean up any existing lockfile to ensure fresh install
      gemfile_lock = File.join(dummy_path, "Gemfile.lock")
      File.delete(gemfile_lock) if File.exist?(gemfile_lock)

      # Generate Gemfile dynamically
      File.write(gemfile_path, <<~GEMFILE)
        # frozen_string_literal: true
        # This file is generated dynamically by rake brakeman:scan
        # Set RAILS_VERSION environment variable to test different versions

        source "https://rubygems.org"

        gem "rails", "#{rails_version}"
        gem "sqlite3", "~> 2.0"
        gem "bunko", path: "../.."
      GEMFILE

      # Run bundle install in dummy-brakeman app
      puts "Running bundle install in test/dummy-brakeman..."
      system("cd #{dummy_path} && bundle install --quiet") || abort("Failed to bundle install")

      # Show the actual installed Rails version
      rails_info = `BUNDLE_GEMFILE=#{gemfile_path} bundle info rails 2>/dev/null | grep "* rails"`
      if rails_info =~ /rails \(([\d.]+)\)/
        puts "Installed Rails: #{$1}"
      end

      # Regenerate baseline files from templates (migrations, models, initializer)
      # This ensures we scan the latest template code
      puts "\nRegenerating baseline files from templates..."
      puts "This ensures Brakeman scans current template code, not stale generated files"

      # Clean up old baseline files
      FileUtils.rm_rf(Dir.glob("#{dummy_path}/db/migrate/*.rb"))
      FileUtils.rm_f("#{dummy_path}/app/models/post.rb")
      FileUtils.rm_f("#{dummy_path}/app/models/post_type.rb")
      FileUtils.rm_f("#{dummy_path}/config/initializers/bunko.rb")
      FileUtils.rm_f("#{dummy_path}/config/routes.rb")

      # Run baseline setup to regenerate from templates
      puts "Running baseline setup..."
      system("cd #{File.expand_path('../..', __dir__)} && bundle exec rake brakeman:baseline_setup") ||
        abort("Failed to run baseline setup")

      # Set up database (delete storage and schema to ensure clean state)
      puts "\nSetting up database..."
      FileUtils.rm_rf("#{dummy_path}/storage")
      FileUtils.rm_f("#{dummy_path}/db/schema.rb")
      FileUtils.mkdir_p("#{dummy_path}/storage")

      system("cd #{dummy_path} && RAILS_ENV=test bundle exec rails db:create") ||
        abort("Failed to create database")

      puts "Running migrations..."
      system("cd #{dummy_path} && RAILS_ENV=test bundle exec rails db:migrate") ||
        abort("Failed to run migrations")

      # Clean up old generated files
      puts "\nCleaning up generated files..."
      FileUtils.rm_rf(Dir.glob("#{dummy_path}/app/views/{blog,docs,articles,videos,pages,shared}"))
      FileUtils.rm_f(Dir.glob("#{dummy_path}/app/controllers/{blog,docs,articles,videos,pages}_controller.rb"))

      # Run bunko:setup to regenerate from templates
      puts "Running bunko:setup to generate controllers and views..."
      system("cd #{dummy_path} && RAILS_ENV=test bundle exec rails bunko:setup") ||
        abort("Failed to regenerate dummy app")

      puts "✓ Regenerated controllers and views from templates\n"

      # Copy gem source into dummy app so Brakeman scans it as app code
      # This allows us to catch vulnerabilities in lib/bunko/* concerns
      # Using app/controllers/concerns so Brakeman treats it as controller code
      dummy_bunko_concerns = File.join(dummy_path, "app/controllers/concerns/bunko_gem")
      gem_bunko_lib = File.expand_path("../../lib/bunko", __dir__)

      begin
        # Copy gem source (will be cleaned up in ensure block)
        FileUtils.mkdir_p(dummy_bunko_concerns)
        FileUtils.cp_r(Dir.glob("#{gem_bunko_lib}/**/*.rb"), dummy_bunko_concerns)
        copied_files = Dir.glob(File.join(dummy_bunko_concerns, "**/*.rb")).size
        puts "Copied gem source: #{gem_bunko_lib} -> #{dummy_bunko_concerns}"
        puts "Copied #{copied_files} Ruby files from gem source"

        puts "\nRunning Brakeman security scan..."
        puts "Scanning: test/dummy-brakeman (including gem source)"
        puts "-" * 80

        $stdout.flush

        tracker = Brakeman.run(
          app_path: dummy_path,
          print_report: true,
          min_confidence: 1, # Show medium and high confidence warnings
          quiet: false
        )

        puts "-" * 80
      ensure
        # Clean up copied files
        if Dir.exist?(dummy_bunko_concerns)
          FileUtils.rm_rf(dummy_bunko_concerns)
          puts "Cleaned up copied gem source: #{dummy_bunko_concerns}"
        end
      end

      if tracker.filtered_warnings.any?
        puts "\n❌ Security warnings found: #{tracker.filtered_warnings.length}"
        exit 1
      else
        puts "\n✅ No security warnings found!"
        exit 0
      end
    end

    desc "Set up baseline test/dummy-brakeman app for Brakeman scanning"
    task :baseline_setup do
      dummy_path = File.expand_path("../../test/dummy-brakeman", __dir__)

      puts "Setting up baseline for test/dummy-brakeman..."

      # Create necessary directories
      FileUtils.mkdir_p("#{dummy_path}/db/migrate")
      FileUtils.mkdir_p("#{dummy_path}/app/models")
      FileUtils.mkdir_p("#{dummy_path}/config/initializers")

      # Copy migrations from lib/tasks/templates (process ERB with defaults)
      migrations_template_dir = File.expand_path("../../lib/tasks/templates/db/migrate", __dir__)
      if Dir.exist?(migrations_template_dir)
        require "erb"

        # Helper methods for ERB context
        context = Object.new
        context.define_singleton_method(:include_seo_fields?) { true } # Include SEO by default
        context.define_singleton_method(:use_json_content?) { false } # Use text by default

        Dir.glob("#{migrations_template_dir}/*.rb.tt").sort.each do |template_file|
          filename = File.basename(template_file, ".tt")
          timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
          # Prepend timestamp to migration filename
          migration_name = "#{timestamp}_#{filename}"

          template_content = File.read(template_file)
          # Replace migration version tag first
          template_content = template_content.gsub("<%= ActiveRecord::Migration.current_version %>", "8.0")
          # Process remaining ERB tags with context
          processed_content = ERB.new(template_content, trim_mode: "-").result(context.instance_eval { binding })
          File.write("#{dummy_path}/db/migrate/#{migration_name}", processed_content)
          sleep(1) # Ensure unique timestamps
        end
        puts "✓ Copied migration files"
      end

      # Copy model files from lib/tasks/templates
      models_template_dir = File.expand_path("../../lib/tasks/templates/models", __dir__)
      if Dir.exist?(models_template_dir)
        Dir.glob("#{models_template_dir}/*.rb.tt").each do |template_file|
          filename = File.basename(template_file, ".tt")
          content = File.read(template_file)
          File.write("#{dummy_path}/app/models/#{filename}", content)
        end
        puts "✓ Copied model files"
      end

      # Copy initializer
      initializer_template = File.expand_path("../../lib/tasks/templates/config/initializers/bunko.rb.tt", __dir__)
      if File.exist?(initializer_template)
        # Create a basic config with blog, docs, articles, videos
        config_content = <<~RUBY
          Bunko.configure do |config|
            config.post_type :blog
            config.post_type :docs, title: "Documentation"
            config.post_type :articles
            config.post_type :videos
          end
        RUBY
        File.write("#{dummy_path}/config/initializers/bunko.rb", config_content)
        puts "✓ Created bunko.rb initializer"
      end

      # Create blank routes.rb (bunko:setup will add bunko routes)
      routes_content = <<~RUBY
        Rails.application.routes.draw do
          # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

          # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
          # Can be used by load balancers and uptime monitors to verify that the app is live.
          get "up" => "rails/health#show", as: :rails_health_check

          # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
          # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
          # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

          # Defines the root path route ("/")
          # root "posts#index"
        end
      RUBY
      File.write("#{dummy_path}/config/routes.rb", routes_content)
      puts "✓ Created routes.rb"

      puts "\nBaseline setup complete!"
      puts "Next steps:"
      puts "  1. Commit the baseline files"
      puts "  2. Run 'rake brakeman:scan' to test"
    end
  end

  desc "Alias for brakeman:scan"
  task brakeman: "brakeman:scan"
rescue LoadError
  # Brakeman not available, skip task definition
  desc "Brakeman not available (run 'bundle install' to enable)"
  task :brakeman do
    puts "Brakeman is not available. Run 'bundle install' to enable security scanning."
  end
end
