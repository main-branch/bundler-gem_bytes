# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Holds the components of a attribute: a name and a value
        #
        # @api public
        #
        # Attributes in the gemspec look like the following:
        #
        # ```ruby
        # Gem::Specification.new do |spec|
        #   spec.name = 'test'
        # end
        # ```
        #
        # @!attribute [r] name
        #   The name of the attribute
        #   @example
        #     attribute.name #=> "test"
        #
        #   @return [String]
        #   @api public
        #
        # @!attribute [r] value
        #   The value of the attribute expressed as an AST tree
        #   @example
        #     attribute.value.to_sexp #=> 's(:str, "my_description")'
        #   @return [Parser::AST::Node]
        #   @api public
        #
        # @!method to_a()
        #   Converts the attribute into an array
        #   @example
        #     dependency.to_a #=> ["description", [:str, "my_description"]]
        #   @return [Array]
        #   @api public
        #
        Attribute = Struct.new(:name, :value) do
          def to_a = [name, value.to_sexp_array]
        end
      end
    end
  end
end
