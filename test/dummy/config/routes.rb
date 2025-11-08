# frozen_string_literal: true

Rails.application.routes.draw do
  # Blog routes
  get "/blog", to: "blog#index", as: :blog_index
  get "/blog/:slug", to: "blog#show", as: :blog

  # Docs routes
  get "/docs", to: "docs#index", as: :docs_index
  get "/docs/:slug", to: "docs#show", as: :docs
end
