# frozen_string_literal: true

class MissingTypeController < ApplicationController
  include Bunko::Controllers::Collection
  bunko_collection :missing_type
end
