# frozen_string_literal: true

module Legal
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
      # e.g., app/views/legal/pages/privacy_policy.html.erb
      if template_exists?(params[:page], "legal/pages")
        render params[:page]
      else
        # Otherwise render the default show.html.erb
        render :show
      end
    end
  end
end
