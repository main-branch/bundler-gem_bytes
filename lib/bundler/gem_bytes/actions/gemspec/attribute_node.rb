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
        #   The AST node for the attribute
        #   @example
        #     attribute_node.node #=> ...
        #   @return [Parser::AST::Node]
        #   @api public
        #
        # @!attribute [r] attribute
        #   The components of the attribute from the AST node
        #   @example
        #     attribute_node.attribute.to_a #=> ["description", [:str, "My deescription"]]
        #   @return [Dependency]
        #   @api public
        #
        AttributeNode = Struct.new(:node, :attribute)
      end
    end
  end
end
