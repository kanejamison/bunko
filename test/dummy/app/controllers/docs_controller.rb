# frozen_string_literal: true

class DocsController < ApplicationController
  bunko_collection :docs, per_page: 5, layout: "application"
end
