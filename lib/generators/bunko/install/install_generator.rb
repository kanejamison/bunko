# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module Bunko
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :skip_views, type: :boolean, default: false,
        desc: "Skip generating view templates"
      class_option :skip_routes, type: :boolean, default: false,
        desc: "Skip modifying routes.rb"
      class_option :skip_seo, type: :boolean, default: false,
        desc: "Skip adding SEO fields (meta_title, meta_description)"
      class_option :skip_metrics, type: :boolean, default: false,
        desc: "Skip adding metrics fields (word_count)"
      class_option :metadata, type: :boolean, default: false,
        desc: "Add metadata field (jsonb/json) to posts table"

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

      def create_controller
        template "blog_controller.rb.tt", "app/controllers/blog_controller.rb"
      end

      def create_views
        return if options[:skip_views]

        template "index.html.erb.tt", "app/views/blog/index.html.erb"
        template "show.html.erb.tt", "app/views/blog/show.html.erb"
      end

      def add_routes
        return if options[:skip_routes]

        route "resources :blog, only: [:index, :show], param: :slug"
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

      def include_metrics?
        !options[:skip_metrics]
      end

      def include_metadata?
        options[:metadata]
      end
    end
  end
end
