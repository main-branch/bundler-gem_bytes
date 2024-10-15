# frozen_string_literal: true

# The bundler namespace within which the GemBytes plugin will be defined
module Bundler
  # A bundler plugin that adds features to your existing Ruby Gems project
  #
  # See [our repository of templates](http://gembytes.com/templates) for adding
  # testing, linting, and security frameworks to your project.
  #
  # @api public
  #
  module GemBytes
  end
end

require_relative 'gem_bytes/bundler_command'
require_relative 'gem_bytes/version'
