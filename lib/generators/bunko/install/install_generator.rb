# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module Bunko
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :skip_seo, type: :boolean, default: false,
        desc: "Skip adding SEO fields (meta_title, meta_description)"
      class_option :json_content, type: :boolean, default: false,
        desc: "Use json/jsonb for content field instead of text (for JSON-based editors)"

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migrations
        migration_template "create_post_types.rb.tt",
          "db/migrate/create_post_types.rb"

        sleep 1 # Ensure different timestamps for migrations

        migration_template "create_posts.rb.tt",
          "db/migrate/create_posts.rb"
      end

      def create_models
        template "post_type.rb.tt", "app/models/post_type.rb"
        template "post.rb.tt", "app/models/post.rb"
      end

      def create_initializer
        template "bunko.rb.tt", "config/initializers/bunko.rb"
      end

      def show_readme
        return unless behavior == :invoke

        say "\n" + ("=" * 79)
        say File.read(File.join(self.class.source_root, "INSTALL.md"))
        say ("=" * 79) + "\n"
      end

      private

      def include_seo_fields?
        !options[:skip_seo]
      end

      def use_json_content?
        options[:json_content]
      end
    end
  end
end
