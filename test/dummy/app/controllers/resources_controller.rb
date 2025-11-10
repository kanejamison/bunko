# frozen_string_literal: true

class ResourcesController < ApplicationController
  include Bunko::Controllers::Collection
  bunko_collection :resources
end
