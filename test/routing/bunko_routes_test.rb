# frozen_string_literal: true

require_relative "../test_helper"
require "bunko/routing"

# Ensure routing methods are available
ActionDispatch::Routing::Mapper.include Bunko::Routing::MapperMethods unless ActionDispatch::Routing::Mapper.include?(Bunko::Routing::MapperMethods)

class BunkoRoutesTest < ActiveSupport::TestCase
  def setup
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      # Tests will define routes in each test method
    end
  end

  test "bunko_collection creates index and show routes with slug param" do
    @routes.draw do
      bunko_collection :blog
    end

    # Get all route paths
    paths = @routes.routes.map { |r| r.path.spec.to_s }

    assert_includes paths, "/blog(.:format)"
    assert_includes paths, "/blog/:slug(.:format)"
  end

  test "bunko_collection converts underscores to hyphens in path" do
    @routes.draw do
      bunko_collection :case_study
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Path should use hyphens
    assert_includes paths, "/case-study(.:format)"
    assert_includes paths, "/case-study/:slug(.:format)"
  end

  test "bunko_collection accepts custom path option" do
    @routes.draw do
      bunko_collection :case_study, path: "case-studies"
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Should use custom path
    assert_includes paths, "/case-studies(.:format)"
    assert_includes paths, "/case-studies/:slug(.:format)"
  end

  test "bunko_collection accepts custom controller option" do
    @routes.draw do
      bunko_collection :blog, controller: "articles"
    end

    # Check controller assignment
    route = @routes.routes.find { |r| r.path.spec.to_s == "/blog(.:format)" }
    assert_equal "articles", route.defaults[:controller]
  end

  test "bunko_collection accepts custom only option" do
    @routes.draw do
      bunko_collection :blog, only: [:index]
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Should have index route
    assert_includes paths, "/blog(.:format)"

    # Should NOT have show route
    refute_includes paths, "/blog/:slug(.:format)"
  end

  test "bunko_collection works with multiple collections" do
    @routes.draw do
      bunko_collection :blog
      bunko_collection :docs
      bunko_collection :changelog
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    assert_includes paths, "/blog(.:format)"
    assert_includes paths, "/docs(.:format)"
    assert_includes paths, "/changelog(.:format)"
  end

  test "bunko_collection generates path helper names from resource name" do
    @routes.draw do
      bunko_collection :blog
    end

    # Helper methods (Rails doesn't generate *_index_path, just the resource name)
    assert_respond_to @routes.url_helpers, :blog_path  # Can be used with or without slug
  end

  test "bunko_collection with custom path generates helpers from path name with underscores" do
    @routes.draw do
      bunko_collection :case_study, path: "case-studies"
    end

    # Helpers use underscored version of path (case-studies → case_studies)
    assert_respond_to @routes.url_helpers, :case_studies_path  # index/collection
    assert_respond_to @routes.url_helpers, :case_study_path    # show/member (Rails singularizes)
  end

  # Static pages routing tests
  test "bunko_page creates single GET route" do
    @routes.draw do
      bunko_page :about
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Should only have one route (no :slug param)
    assert_includes paths, "/about(.:format)"
    refute_includes paths, "/about/:page(.:format)"
  end

  test "bunko_page converts underscores to hyphens in path" do
    @routes.draw do
      bunko_page :privacy_policy
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Path should use hyphens
    assert_includes paths, "/privacy-policy(.:format)"
  end

  test "bunko_page routes to pages#show by default" do
    @routes.draw do
      bunko_page :about
    end

    route = @routes.routes.find { |r| r.path.spec.to_s == "/about(.:format)" }
    assert_equal "pages", route.defaults[:controller]
    assert_equal "show", route.defaults[:action]
  end

  test "bunko_page passes page param in defaults" do
    @routes.draw do
      bunko_page :contact
    end

    route = @routes.routes.find { |r| r.path.spec.to_s == "/contact(.:format)" }
    assert_equal "contact", route.defaults[:page]
  end

  test "bunko_page accepts custom path option" do
    @routes.draw do
      bunko_page :about, path: "about-us"
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    # Should use custom path
    assert_includes paths, "/about-us(.:format)"
    refute_includes paths, "/about(.:format)"
  end

  test "bunko_page accepts custom controller option" do
    @routes.draw do
      bunko_page :contact, controller: "static_pages"
    end

    route = @routes.routes.find { |r| r.path.spec.to_s == "/contact(.:format)" }
    assert_equal "static_pages", route.defaults[:controller]
  end

  test "bunko_page generates path helper" do
    @routes.draw do
      bunko_page :about
    end

    # Helper uses underscored page name
    assert_respond_to @routes.url_helpers, :about_path
  end

  test "bunko_page works with multiple pages" do
    @routes.draw do
      bunko_page :about
      bunko_page :contact
      bunko_page :privacy_policy
    end

    paths = @routes.routes.map { |r| r.path.spec.to_s }

    assert_includes paths, "/about(.:format)"
    assert_includes paths, "/contact(.:format)"
    assert_includes paths, "/privacy-policy(.:format)"
  end
end
