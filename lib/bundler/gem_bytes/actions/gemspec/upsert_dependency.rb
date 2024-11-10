# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Add or update a dependency in a gemspec
        #
        # If a dependency on the given gem is not found, a new dependency is added to
        # the end of the Gem::Specification block.
        #
        # If one or more dependencies are found on the same gem as new_dependency,
        # the version constraint is updated to the new_dependency version constraint.
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
        # @!attribute [r] new_dependency
        #   The dependency declaration to add or update
        #   @return [Dependency]
        #   @api private
        #
        # @api public
        class UpsertDependency
          # Initializes the upsert dependency action
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

          attr_reader :tree_rewriter, :gemspec_block, :receiver_name, :dependencies, :new_dependency

          # Adds or updates a dependency to the Gem::Specification block
          #
          # @example
          #   upsert_dependency = UpsertDependency.new(tree_rewriter, gemspec_block, receiver_name, dependencies)
          #   new_dependency = Dependency.new(:add_runtime_dependency, 'rubocop', '~> 1.68')
          #   upsert_dependency.call(new_dependency)
          # @param new_dependency [Dependency] The dependency declaration to add or update
          # @return [void]
          # @api public
          def call(new_dependency)
            @new_dependency = new_dependency
            matching_dependencies = dependencies.select { |d| d.dependency.gem_name == new_dependency.gem_name }

            if matching_dependencies.any?
              update_dependencies(matching_dependencies)
            else
              add_dependency
            end
          end

          # Update the version constraint of the existing dependency(s)
          # @param matching_dependencies [Array<DependencyNode>] The existing dependencies that match new_dependency
          # @return [void]
          # @api private
          def update_dependencies(matching_dependencies)
            matching_dependencies.each do |found_dependency|
              raise(dependency_type_conflict_error(found_dependency)) unless dependency_type_match?(found_dependency)

              tree_rewriter.replace(found_dependency.node.loc.expression, dependency_source_code(found_dependency))
            end
          end

          # Add the new_dependency to the end of the Gem::Specification block
          # @return [void]
          # @api private
          def add_dependency
            # Add the dependency to the end of the Gem::Specification block
            internal_block = gemspec_block.children[2]
            if internal_block
              tree_rewriter.insert_after(internal_block.children.last.loc.expression, "\n  #{dependency_source_code}")
            else
              # When the Gem::Specification block is empty, it require special handling
              add_dependency_to_empty_gemspec_block
            end
          end

          # Error message for a dependency type conflict
          # @param existing_dependency [DependencyNode] The existing dependency
          # @return [String] The error message
          # @api private
          def dependency_type_conflict_error(existing_dependency)
            # :nocov: JRuby give false positive for this line being uncovered by tests
            <<~MESSAGE.chomp.gsub("\n", ' ')
              Trying to add a
              #{dependency_method_to_type(new_dependency.method_name).upcase}
              dependency on "#{new_dependency.gem_name}" which conflicts with the existing
              #{dependency_method_to_type(existing_dependency.dependency.method_name).upcase}
              dependency.
            MESSAGE
            # :nocov:
          end

          # The dependency type (:runtime or :development) based on a given method name
          # @param method [Symbol] The method name to convert to a dependency type
          # @return [Symbol] The dependency type
          # @api private
          def dependency_method_to_type(method)
            method == :add_development_dependency ? :development : :runtime
          end

          # Checks if the new dependency type is the same as the existing dependency type
          #
          # @param existing_dependency [DependencyNode] The existing dependency
          # @return [Boolean] Whether the dependency type conflicts
          # @api private
          def dependency_type_match?(existing_dependency)
            # Either both are :add_development_dependency or both are not
            (existing_dependency.dependency.method_name == :add_development_dependency) ==
              (new_dependency.method_name == :add_development_dependency)
          end

          # Add new_dependency to an empty Gem::Specification block
          # @return [void]
          # @api private
          def add_dependency_to_empty_gemspec_block
            source = gemspec_block.loc.expression.source
            # :nocov: supress false reporting of no coverage of multiline string literals on JRuby
            tree_rewriter.replace(gemspec_block.loc.expression, <<~GEMSPEC_BLOCK.chomp)
              #{source[0..-5]}
                #{dependency_source_code}
              #{source[-3..]}
            GEMSPEC_BLOCK
            # :nocov:
          end

          # The source code for the updated dependency declaration
          # @param existing_dependency [DependencyNode] The existing dependency
          # @return [String] The source code for the dependency declaration
          # @api private
          def dependency_source_code(existing_dependency = nil)
            # Use existing quote character for string literals
            q = new_quote_char(existing_dependency)

            # :nocov: supress false reporting of no coverage of multiline string literals on JRuby
            "#{receiver_name}.#{new_method_name(existing_dependency)} " \
              "#{q}#{new_dependency.gem_name}#{q}, " \
              "#{q}#{new_dependency.version_constraint}#{q}"
            # :nocov:
          end

          # Use the same quote char as the existing dependency or default to single quote
          # @param existing_dependency [DependencyNode, nil] The existing dependency being updated
          # @return [String] The quote character to use
          # @api private
          def new_quote_char(existing_dependency)
            if existing_dependency
              existing_dependency.node.children[3].loc.expression.source[0]
            else
              "'"
            end
          end

          # The method to use for the new dependency
          #
          # If `existing_dependency` is given and the dependency type (runtime vs.
          # development) matches, the existing dependency method is used. Otherwise,
          # the new_dependency method is used.
          #
          # The purpose of this method is ensure that an #add_dependency call is not
          # replaced with an #add_runtime_dependency call or vice versa. This
          # maintains consistency within the user's gemspec even though these methods
          # are functionally equivalent.
          #
          # @param existing_dependency [DependencyNode, nil] The existing dependency being updated
          # @return [Symbol] The method to use for the new dependency
          # @api private
          def new_method_name(existing_dependency)
            if existing_dependency && dependency_type_match?(existing_dependency)
              existing_dependency.dependency.method_name
            else
              new_dependency.method_name
            end
          end
        end
      end
    end
  end
end
