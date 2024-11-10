# frozen_string_literal: true

require 'bundler/gem_bytes'

module Bundler
  module GemBytes
    # The API for GemBytes templates
    # @api public
    module Actions
      # The gemspec at `gemspec_path` is updated per instructions in `action_block`
      #
      # @example Adding a runtime dependency
      #   actions = Actions.new
      #   actions.gemspec(gemspec_path: 'test.gemspec') do
      #     add_runtime_dependency 'rubocop', '~> 1.68'
      #   end
      #
      # @param gemspec_path [String] the path to the gemspec file to process
      #
      #   Defaults to the first gemspec file found in the current directory.
      #
      # @yield a block with instructions to modify the gemspec
      #
      #   This block is run in the context of a {GemBytes::Actions::Gemspec} instance.
      #   The instructions are methods defined by this instance (e.g.
      #   `add_dependency`, `remove_dependency`, etc.)
      #
      # @yieldparam gemspec_name [Symbol] the name of the Gem::Specification varaible used in the gemspec
      # @yieldparam gemspec [Gem::Specification] the evaluated gemspec
      # @yieldreturn [String] the updated gemspec
      #
      # @return [void]
      def gemspec(gemspec_path: Dir['*.gemspec'].first, &action_block)
        source = File.read(gemspec_path)
        action = Bundler::GemBytes::Actions::Gemspec.new(context: self)
        updated_source = action.call(source, path: gemspec_path, &action_block)
        File.write(gemspec_path, updated_source)
      end
    end
  end
end

require_relative 'actions/gemspec'
