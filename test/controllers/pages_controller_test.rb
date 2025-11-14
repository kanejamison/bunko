# frozen_string_literal: true

require_relative "../test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Reset configuration before each test
    Bunko.reset_configuration!
    Bunko.configure do |config|
      config.allow_static_pages = true
    end

    # Reload routes to pick up the new configuration
    Rails.application.reload_routes!

    @pages_type = PostType.create!(name: "pages", title: "Pages")

    # Create pages with hyphenated slugs (matching Post.slug auto-generation)
    @about_page = Post.create!(
      title: "About Us",
      slug: "about-us",  # Hyphenated (from parameterize)
      content: "About our company",
      post_type: @pages_type,
      status: "published",
      published_at: 1.day.ago
    )

    @privacy_page = Post.create!(
      title: "Privacy Policy",
      slug: "privacy-policy",  # Hyphenated (from parameterize)
      content: "Our privacy policy",
      post_type: @pages_type,
      status: "published",
      published_at: 1.day.ago
    )

    @terms_page = Post.create!(
      title: "Terms and Conditions",
      slug: "terms-and-conditions",  # Hyphenated (from parameterize)
      content: "Our terms",
      post_type: @pages_type,
      status: "published",
      published_at: 1.day.ago
    )
  end

  test "bunko_page finds page with hyphenated slug" do
    get "/about-us"
    assert_response :success
  end

  test "bunko_page with underscored route name finds hyphenated slug" do
    # Route defined as bunko_page :privacy_policy (underscored)
    # URL is /privacy-policy (hyphenated)
    # Database slug is "privacy-policy" (hyphenated)
    get "/privacy-policy"
    assert_response :success
    assert_match "Privacy Policy", response.body
  end

  test "bunko_page with multi-word underscored route finds hyphenated slug" do
    # Route defined as bunko_page :terms_and_conditions (underscored)
    # URL is /terms-and-conditions (hyphenated)
    # Database slug is "terms-and-conditions" (hyphenated)
    get "/terms-and-conditions"
    assert_response :success
    assert_match "Terms and Conditions", response.body
  end

  test "bunko_page returns 404 for non-existent page" do
    get "/non-existent"
    assert_response :not_found
  end

  test "bunko_page returns 404 for draft pages" do
    Post.create!(
      title: "Draft Page",
      slug: "draft-page",
      content: "Draft content",
      post_type: @pages_type,
      status: "draft"
    )

    get "/draft-page"
    assert_response :not_found
  end

  # Namespace tests
  test "bunko_page works inside namespace" do
    # The namespace route looks for the same pages as non-namespaced routes
    # It's just a different URL path to reach them
    # We already have @privacy_page and @terms_page from setup

    get "/legal/privacy-policy"
    assert_response :success
    assert_match "Our privacy policy", response.body

    get "/legal/terms-and-conditions"
    assert_response :success
    assert_match "Our terms", response.body
  end

  test "bunko_page in namespace with underscored route name finds hyphenated slug" do
    # Route defined as: namespace :legal do bunko_page :terms_and_conditions end
    # Should find Post with slug "terms-and-conditions"
    # We already have @terms_page from setup with slug "terms-and-conditions"

    get "/legal/terms-and-conditions"
    assert_response :success
    assert_match "Terms and Conditions", response.body
  end

  # Security tests for path traversal prevention
  test "query string params cannot override page slug" do
    # Attack: Try to load a different page via query string
    get "/about-us?page=privacy-policy"
    assert_response :success
    # Should still load the "about-us" page, not privacy-policy
    assert_match "About our company", response.body
    assert_no_match "Our privacy policy", response.body
  end

  test "path traversal via query string is ignored" do
    # Attack: Try to use path traversal in params
    get "/about-us?page=../../etc/passwd"
    assert_response :success
    # Should still load the "about-us" page
    assert_match "About our company", response.body
  end

  test "malicious template names in query string are ignored" do
    # Attack: Try to render arbitrary templates
    get "/about-us?page=admin/users"
    assert_response :success
    # Should still load the "about-us" page from the path
    assert_match "About our company", response.body
  end

  test "trailing slashes do not affect page resolution" do
    get "/about-us/"
    assert_response :success
    assert_match "About our company", response.body
  end

  test "namespaced routes ignore query string params" do
    get "/legal/privacy-policy?page=terms-and-conditions"
    assert_response :success
    # Should load privacy-policy, not terms-and-conditions
    assert_match "Our privacy policy", response.body
    assert_no_match "Our terms", response.body
  end
end
