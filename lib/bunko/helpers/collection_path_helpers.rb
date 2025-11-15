# frozen_string_literal: true

module Bunko
  module Helpers
    # Dynamically overrides path helpers for Bunko collections to automatically extract slugs
    # from Post objects, making link generation ergonomic: blog_path(@post) instead of blog_path(@post.slug)
    module CollectionPathHelpers
      def self.install!
        # Generate override methods for each registered collection
        Bunko.configuration.collection_path_helpers.each do |resource_name|
          define_path_helper_override(resource_name)
        end
      end

      def self.define_path_helper_override(resource_name)
        # Override both _path and _url helpers
        define_method "#{resource_name}_path" do |post_or_slug = nil, *args|
          if post_or_slug.respond_to?(:slug)
            # It's a Post object - extract the slug
            super(post_or_slug.slug, *args)
          else
            # It's already a slug string, or nil for index route
            super(post_or_slug, *args)
          end
        end

        define_method "#{resource_name}_url" do |post_or_slug = nil, *args|
          if post_or_slug.respond_to?(:slug)
            # It's a Post object - extract the slug
            super(post_or_slug.slug, *args)
          else
            # It's already a slug string, or nil for index route
            super(post_or_slug, *args)
          end
        end
      end
    end
  end
end
