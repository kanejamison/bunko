# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    # Extract page slug from request path (not user-controllable params)
    # This prevents path traversal attacks via query string manipulation
    # e.g., GET /about?page=../../admin/users
    page_slug = request.path.split("/").reject(&:empty?).last

    @post = Post.published.find_by(
      post_type: PostType.find_by(name: "pages"),
      slug: page_slug
    )

    unless @post
      raise ActiveRecord::RecordNotFound, "Page not found"
    end

    # Check if a custom view exists for this page
    # Use DB-validated slug to prevent rendering arbitrary templates
    # e.g., app/views/pages/about.html.erb
    if template_exists?(@post.slug, "pages")
      render @post.slug
    else
      # Otherwise render the default show.html.erb
      render :show
    end
  end
end
