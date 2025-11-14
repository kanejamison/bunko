# frozen_string_literal: true

Rails.application.routes.draw do
  # Blog routes (PostType)
  bunko_collection :blog

  # Docs routes (PostType)
  bunko_collection :docs

  # Articles routes (PostType) - for collection routing tests
  bunko_collection :articles

  # Videos routes (PostType) - for collection routing tests
  bunko_collection :videos

  # Long Reads (Collection) - for collection routing tests
  bunko_collection :long_reads

  # All Content (Collection) - for collection routing tests
  bunko_collection :all_content

  # Test routes for nonexistent PostType
  get "/nonexistent", to: "nonexistent#index", as: :nonexistent_index
  get "/nonexistent/:slug", to: "nonexistent#show", as: :nonexistent
end
