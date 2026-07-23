# frozen_string_literal: true

module Legal
  class PagesController < ApplicationController
    # Matches Bunko's slug format (lowercase letters, digits, hyphens)
    PAGE_SLUG_FORMAT = /\A[a-z0-9-]+\z/

    def show
      # The bunko_page route supplies the slug via defaults: {page: ...}.
      # Route defaults become path parameters, which take precedence over
      # query string params in Rails, so a visitor cannot override the slug
      # with e.g. GET /legal/privacy-policy?page=other-page
      page_slug = params[:page].to_s

      unless page_slug.match?(PAGE_SLUG_FORMAT)
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
