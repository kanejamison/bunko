# frozen_string_literal: true

class DocsController < ApplicationController
  bunko_collection :docs, per_page: 5

  # The bunko_collection method automatically provides index and show actions.
  #
  # To customize, you can override these methods:
  #
  # def index
  #   super # calls bunko_collection's index
  #   # Add your customizations here
  # end
  #
  # def show
  #   super # calls bunko_collection's show
  #   # Add your customizations here
  # end
  #
  # Available instance variables in your views:
  # - @posts (index action)
  # - @post (show action)
  # - @collection_name
  # - @pagination
end
