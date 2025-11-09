# frozen_string_literal: true

require_relative "test_helper"

class TestBunko < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bunko::VERSION
  end

  def test_configuration_has_defaults
    assert_equal 250, Bunko.configuration.reading_speed
    assert_equal %w[draft published scheduled], Bunko.configuration.valid_statuses
  end

  def test_can_configure_bunko
    Bunko.configure do |config|
      config.reading_speed = 200
    end

    assert_equal 200, Bunko.configuration.reading_speed

    # Reset for other tests
    Bunko.reset_configuration!
    assert_equal 250, Bunko.configuration.reading_speed
  end
end
