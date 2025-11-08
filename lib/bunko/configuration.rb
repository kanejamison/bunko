# frozen_string_literal: true

module Bunko
  class Configuration
    attr_accessor :reading_speed, :valid_statuses

    def initialize
      @reading_speed = 250 # words per minute
      @valid_statuses = %w[draft published scheduled]
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
