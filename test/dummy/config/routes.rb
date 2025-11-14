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

  # Static pages - for bunko_page routing tests
  bunko_page :about_us
  bunko_page :privacy_policy
  bunko_page :terms_and_conditions
  bunko_page :draft_page
  bunko_page :non_existent

  # Namespaced pages - test bunko_page in namespace
  namespace :legal do
    bunko_page :privacy_policy
    bunko_page :terms_and_conditions
  end

  # Test routes for nonexistent PostType
  get "/nonexistent", to: "nonexistent#index", as: :nonexistent_index
  get "/nonexistent/:slug", to: "nonexistent#show", as: :nonexistent
end
