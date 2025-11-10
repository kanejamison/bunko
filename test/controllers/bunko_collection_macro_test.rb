# frozen_string_literal: true

require_relative "../test_helper"

class BunkoCollectionMacroTest < ActiveSupport::TestCase
  class MinimalController < ApplicationController
    # Only call bunko_collection - no manual includes
    bunko_collection :blog
  end

  test "bunko_collection macro automatically includes Collection concern" do
    assert MinimalController.included_modules.include?(Bunko::Controllers::Collection),
      "Collection concern should be automatically included"
  end

  test "bunko_collection macro sets collection name" do
    assert_equal "blog", MinimalController.bunko_collection_name
  end

  test "bunko_collection macro sets default options" do
    options = MinimalController.bunko_collection_options
    assert_equal 10, options[:per_page]
    assert_equal :published_at_desc, options[:order]
  end

  test "bunko_collection macro with custom options" do
    controller_class = Class.new(ApplicationController) do
      bunko_collection :docs, per_page: 5, order: :created_at_asc
    end

    assert_equal "docs", controller_class.bunko_collection_name
    assert_equal 5, controller_class.bunko_collection_options[:per_page]
    assert_equal :created_at_asc, controller_class.bunko_collection_options[:order]
  end

  test "bunko_collection macro defines index action" do
    controller = MinimalController.new
    assert_respond_to controller, :index
  end

  test "bunko_collection macro defines show action" do
    controller = MinimalController.new
    assert_respond_to controller, :show
  end
end
