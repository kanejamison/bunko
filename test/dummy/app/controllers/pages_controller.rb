# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    @post = Post.published.find_by(
      post_type: PostType.find_by(name: "pages"),
      slug: params[:page]
    )

    unless @post
      raise ActiveRecord::RecordNotFound, "Page not found: #{params[:page]}"
    end

    # Check if a custom view exists for this page
    # e.g., app/views/pages/about.html.erb
    if template_exists?(params[:page], "pages")
      render params[:page]
    else
      # Otherwise render the default show.html.erb
      render :show
    end
  end
end
