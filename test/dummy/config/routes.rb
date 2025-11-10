# frozen_string_literal: true

Rails.application.routes.draw do
  # Blog routes
  get "/blog", to: "blog#index", as: :blog_index
  get "/blog/:slug", to: "blog#show", as: :blog

  # Docs routes
  get "/docs", to: "docs#index", as: :docs_index
  get "/docs/:slug", to: "docs#show", as: :docs

  # Test routes for nonexistent PostType
  get "/nonexistent", to: "nonexistent#index", as: :nonexistent_index
  get "/nonexistent/:slug", to: "nonexistent#show", as: :nonexistent

  # Multi-type collection routes
  bunko_collection :resources

  # Scoped collection routes
  bunko_collection :long_reads, path: "long-reads"

  # Missing type routes
  bunko_collection :missing_type
end
