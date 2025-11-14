# frozen_string_literal: true

require "erb"

module Bunko
  module RakeHelpers
    def render_template(template_name, locals = {})
      template_path = File.expand_path("../templates/#{template_name}", __dir__)

      unless File.exist?(template_path)
        raise "Template file not found: #{template_path}"
      end

      template_content = File.read(template_path)

      # Create a context object with all local variables as methods
      context = Object.new
      locals.each do |key, value|
        context.define_singleton_method(key) { value }
      end

      ERB.new(template_content, trim_mode: "-").result(context.instance_eval { binding })
    end
  end
end
