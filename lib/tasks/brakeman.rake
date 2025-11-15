# frozen_string_literal: true

begin
  require "brakeman"

  namespace :brakeman do
    desc "Run Brakeman security scan against test dummy app"
    task :scan do
      dummy_path = File.expand_path("../../test/dummy", __dir__)
      gemfile_path = File.join(dummy_path, "Gemfile")

      # Determine Rails version to test (from ENV or default)
      rails_version = ENV["RAILS_VERSION"] || ">= 8.0"

      puts "Setting up test dummy app for Brakeman..."
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
      GEMFILE

      # Run bundle install in dummy app
      puts "Running bundle install in test/dummy..."
      system("cd #{dummy_path} && bundle install --quiet") || abort("Failed to bundle install")

      # Show the actual installed Rails version
      rails_info = `BUNDLE_GEMFILE=#{gemfile_path} bundle info rails 2>/dev/null | grep "* rails"`
      if rails_info =~ /rails \(([\d.]+)\)/
        puts "Installed Rails: #{$1}"
      end

      puts "\nRunning Brakeman security scan..."
      puts "Scanning: test/dummy"
      puts "-" * 80

      $stdout.flush

      tracker = Brakeman.run(
        app_path: dummy_path,
        print_report: true,
        min_confidence: 1, # Show medium and high confidence warnings
        quiet: false
      )

      puts "-" * 80

      if tracker.filtered_warnings.any?
        puts "\n❌ Security warnings found: #{tracker.filtered_warnings.length}"
        exit 1
      else
        puts "\n✅ No security warnings found!"
        exit 0
      end
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
