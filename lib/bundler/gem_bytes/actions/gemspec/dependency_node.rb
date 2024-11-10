# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Maps a dependency declaration to the AST that represents it
        # @api public
        #
        # @!attribute [r] node
        #   The AST node for the dependency declaration
        #   @example
        #     dependency_node.node #=> ...
        #   @return [Parser::AST::Node]
        #   @api public
        #
        # @!attribute [r] dependency
        #   The components of the dependency declaration from the AST node
        #   @example
        #     dependency_node.dependency.to_a #=> [:add_dependency, 'rubocop', '~> 1.68']
        #   @return [Dependency]
        #   @api public
        #
        DependencyNode = Struct.new(:node, :dependency)
      end
    end
  end
end
