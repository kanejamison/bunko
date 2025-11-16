# frozen_string_literal: true

begin
  require "brakeman"

  namespace :brakeman do
    desc "Run Brakeman security scan using vendor approach (--no-skip-vendor)"
    task :vendor_scan do
      root_path = File.expand_path("../..", __dir__)
      dummy_path = File.expand_path("../../test/dummy", __dir__)
      vendor_bunko_path = File.join(dummy_path, "vendor/bunko")

      puts "=" * 80
      puts "Brakeman Vendor-Based Security Scan"
      puts "=" * 80
      puts "This approach copies the bunko gem into test/dummy/vendor/"
      puts "and uses Brakeman's --no-skip-vendor flag to scan it.\n\n"

      # Step 1: Copy bunko source to vendor/bunko
      puts "Step 1: Copying bunko source to vendor/bunko..."
      puts "-" * 80

      # Clean up old vendor/bunko
      FileUtils.rm_rf(vendor_bunko_path) if File.exist?(vendor_bunko_path)
      FileUtils.mkdir_p(vendor_bunko_path)

      # Copy lib directory
      lib_source = File.join(root_path, "lib")
      lib_dest = File.join(vendor_bunko_path, "lib")
      FileUtils.cp_r(lib_source, lib_dest)

      # Copy tasks directory (contains templates and rake tasks)
      tasks_source = File.join(root_path, "lib/tasks")
      if File.exist?(tasks_source)
        tasks_dest = File.join(vendor_bunko_path, "lib/tasks")
        FileUtils.cp_r(tasks_source, tasks_dest)
      end

      # Count copied files
      copied_files = Dir.glob("#{vendor_bunko_path}/**/*.{rb,rake,tt,erb}").size
      ruby_files = Dir.glob("#{vendor_bunko_path}/**/*.rb").size

      puts "✓ Copied #{ruby_files} Ruby files to vendor/bunko/"
      puts "✓ Total files (including templates): #{copied_files}"

      puts "\nStep 2: Running Brakeman with --no-skip-vendor..."
      puts "-" * 80

      # Step 2: Run Brakeman with --no-skip-vendor
      tracker = Brakeman.run(
        app_path: dummy_path,
        print_report: true,
        skip_vendor: false,  # This is the key setting!
        min_confidence: 1,   # Show medium and high confidence warnings
        quiet: false
      )

      # Step 3: Report results
      puts "\n" + "=" * 80
      puts "Scan Complete"
      puts "=" * 80

      if tracker.filtered_warnings.any?
        puts "⚠️  Found #{tracker.filtered_warnings.size} warning(s)"
        exit 1
      else
        puts "✓ No security warnings found!"
        exit 0
      end
    end

    desc "Clean up vendor/bunko and related files"
    task :vendor_clean do
      dummy_path = File.expand_path("../../test/dummy", __dir__)

      puts "Cleaning up vendor/bunko..."
      FileUtils.rm_rf("#{dummy_path}/vendor/bunko")
      puts "✓ Cleaned up vendor/bunko"
    end
  end
rescue LoadError
  # Brakeman not available, skip task
  desc "Brakeman is not installed"
  task :brakeman do
    puts "Brakeman is not installed. Add it to your Gemfile to use security scanning."
  end
end
