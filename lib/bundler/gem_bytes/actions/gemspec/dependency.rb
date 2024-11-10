# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Holds the components of a dependency declaration
        #
        # @api public
        #
        # A dependency declaration is a call to `add_dependency`,
        # `add_runtime_dependency`, or `add_development_dependency` in the
        # Gem::Specification block.
        #
        # For example, the following is a dependency declaration:
        #
        # ```ruby
        # spec.add_dependency 'rubocop', '~> 1.0'
        # ```
        #
        # Would be represented by a Dependency object with the following
        # attributes:
        #   * method_name: :add_dependency
        #   * gem_name: 'rubocop'
        #   * version_constraint: '~> 1.0'
        #
        # @!attribute [r] method_name
        #   The name of the method called to add the dependency
        #
        #   Must be one of the following:
        #
        #   * :add_dependency
        #   * :add_runtime_dependency
        #   * :add_development_dependency
        #
        #   @example
        #     dependency.method_name #=> :add_dependency
        #
        #   @return [Symbol]
        #   @api public
        #
        # @!attribute [r] gem_name
        #   The name of the gem being depended on
        #   @example
        #     dependency.gem_name #=> "rubocop"
        #   @return [String]
        #   @api public
        #
        # @!attribute [r] version_constraint
        #   The version constraint for the dependency (e.g., '~> 1.0')
        #   @example
        #     dependency.version_constraint #=> "~> 1.68"
        #   @return [String]
        #   @api public
        #
        # @!method to_a()
        #   Converts the dependency into an array
        #   @example
        #     dependency.to_a #=> [:add_runtime_dependency, "rubocop", "~> 1.68"]
        #   @return [Array]
        #   @api public
        #
        Dependency = Struct.new(:method_name, :gem_name, :version_constraint) do
          def to_a = [method_name, gem_name, version_constraint]
        end
      end
    end
  end
end
