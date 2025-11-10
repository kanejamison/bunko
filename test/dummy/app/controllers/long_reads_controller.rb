# frozen_string_literal: true

class LongReadsController < ApplicationController
  include Bunko::Controllers::Collection
  bunko_collection :long_reads
end
