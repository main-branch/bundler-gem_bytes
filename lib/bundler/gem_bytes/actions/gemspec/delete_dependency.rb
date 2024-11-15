# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Remove a dependency in a gemspec
        #
        # If a dependency on the given gem is not found, this action does nothing.
        #
        # If one or more dependencies are found on the same gem as gem_name,
        # the are removed from the gemspec.
        #
        # The gemspec is updated via calls to the tree_rewriter object.
        #
        # @!attribute [r] tree_rewriter
        #   The object that updates the source
        #   @return [Parser::TreeRewriter]
        #   @api private
        #
        # @!attribute [r] gemspec_block
        #   The root AST node of the Gem::Specification block from the gemspec
        #   @return [Parser::AST::Node]
        #   @api private
        #
        # @!attribute [r] receiver_name
        #   The name of the receiver for the Gem::Specification block
        #   @return [Symbol]
        #   @api private
        #
        # @!attribute [r] dependencies
        #   The dependency declarations found in the gemspec file
        #   @return [Array<DependencyNode>]
        #   @api private
        #
        # @!attribute [r] gem_name
        #   The name of the gem to remove dependency on
        #   @return [String]
        #   @api private
        #
        # @api public
        class DeleteDependency
          # Initializes the delete dependency action
          # @param tree_rewriter [Parser::TreeRewriter] The object that updates the source
          # @param gemspec_block [Parser::AST::Node] The Gem::Specification block
          # @param receiver_name [Symbol] The name of the receiver for the Gem::Specification block
          # @param dependencies [Array<DependencyNode>] The dependency declarations found in the gemspec file
          # @api private
          def initialize(tree_rewriter, gemspec_block, receiver_name, dependencies)
            @tree_rewriter = tree_rewriter
            @gemspec_block = gemspec_block
            @receiver_name = receiver_name
            @dependencies = dependencies
          end

          attr_reader :tree_rewriter, :gemspec_block, :receiver_name, :dependencies, :gem_name

          # Adds or updates a dependency to the Gem::Specification block
          #
          # @example
          #   delete_dependency = DeleteDependency.new(tree_rewriter, gemspec_block, receiver_name, dependencies)
          #   gem_name = 'rubocop'
          #   depete_dependency.call(gem_name)
          # @param gem_name [String] The name of the gem to remove dependency on
          # @return [void]
          # @api public
          def call(gem_name)
            @gem_name = gem_name
            matching_dependencies = dependencies.select { |d| d.dependency.gem_name == gem_name }

            delete_dependencies(matching_dependencies) if matching_dependencies.any?
          end

          # Removes the matching dependencies from the gemspec
          # @param matching_dependencies [Array<DependencyNode>] The existing dependencies that match gem_name
          # @return [void]
          # @api private
          def delete_dependencies(matching_dependencies)
            matching_dependencies.each do |found_dependency|
              tree_rewriter.replace(full_line_range(found_dependency), '')
            end
          end

          private

          # Expand the range for a node to include any leading whitespace and newline
          # @param dependency_node [DependencyNode] The node to remove
          # @return [Parser::Source::Range] The range of the whole line including whitespace
          # @api private
          def full_line_range(dependency_node)
            range = dependency_node.node.loc.expression
            source_buffer = range.source_buffer
            # The whole line including leading and trailing whitespace
            line_range = source_buffer.line_range(range.line)
            # Expand the range to include the leading newline
            line_range.with(begin_pos: line_range.begin_pos - 1)
          end
        end
      end
    end
  end
end
