# frozen_string_literal: true

module Legal
  class PagesController < ApplicationController
    def show
      # The page slug comes from the route's defaults (bunko_page sets
      # defaults: {page: ...}). Route defaults are path parameters, which
      # take precedence over query string params in Rails, so
      # e.g. GET /legal/privacy-policy?page=../../admin/users cannot
      # override the slug.
      page_slug = params[:page].to_s

      # Format guard in case this action is wired up without a :page default
      unless page_slug.match?(/\A[a-z0-9-]+\z/)
        raise ActiveRecord::RecordNotFound, "Page not found"
      end

      @post = Post.published.find_by(
        post_type: PostType.find_by(name: "pages"),
        slug: page_slug
      )

      unless @post
        raise ActiveRecord::RecordNotFound, "Page not found"
      end

      # Check if a custom view exists for this page
      # Use DB-validated slug to prevent rendering arbitrary templates
      # e.g., app/views/legal/pages/privacy_policy.html.erb
      if template_exists?(@post.slug, "legal/pages")
        render @post.slug
      else
        # Otherwise render the default show.html.erb
        render :show
      end
    end
  end
end
