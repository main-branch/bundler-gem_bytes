# frozen_string_literal: true

require 'bundler/gem_bytes'

module Bundler
  module GemBytes
    # The API for GemBytes templates
    # @api public
    module Actions
      # Adds (or updates) a dependency in the project's gemspec file
      #
      # @example
      #   add_dependency(:development, 'rspec', '~> 3.13')
      #   add_dependency(:runtime, 'activesupport', '>= 6.0.0')
      #
      # @param dependency_type [Symbol] the type of dependency to add (either :development or :runtime)
      # @param gem_name [String] the name of the gem to add
      # @param version_constraint [String] the version constraint for the gem
      # @param force [Boolean] whether to overwrite the existing dependency
      # @param gemspec [String] the path to the gemspec file
      #
      # @return [void]
      #
      # @api public
      #
      def add_dependency(dependency_type, gem_name, version_constraint, force: false, gemspec: Dir['*.gemspec'].first)
        source = File.read(gemspec)
        updated_source = Bundler::GemBytes::Gemspec::UpsertDependency.new(
          dependency_type, gem_name, version_constraint, force: force
        ).call(source, path: gemspec)
        File.write(gemspec, updated_source)
      end
    end
  end
end
