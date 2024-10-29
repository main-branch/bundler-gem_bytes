# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Gemspec
      # Add or update a dependency in a gemspec file
      #
      # This class allows the addition of a new dependency or the updating of an
      # existing dependency in a gemspec file.
      #
      # This class works by parsing the gemspec file into an AST and then walking the
      # AST to find the Gem::Specification block (via #on_block). Once the block is
      # found, AST within that block is walked to locate the dependency declarations
      # (via #on_send). Any dependency declaration that matches the given gem name is
      # collected into the found_dependencies array.
      #
      # Once the Gem::Specification block is fully processed, if a dependency on the
      # given gem is not found, a new dependency is added to the end of the
      # Gem::Specification block.
      #
      # If one or more dependencies are found, the version constraint is updated to
      # the given version constraint. If the dependency type is different from the
      # existing dependency, an error is raised unless the `force` option is set to
      # true.
      #
      # @example
      #   require 'bundler/gem_bytes'
      #
      #   add_dependency = Bundler::GemBytes::Gemspec::UpsertDependency.new(:dependency, 'test_tool', '~> 2.1')
      #
      #   gemspec = File.read('bundler-gem_bytes.gemspec')
      #   updated_gemspec = add_dependency.call(gemspec)
      #   File.write('project.gemspec', updated_gemspec)
      #
      # @!attribute [r] dependency_type
      #   The type of dependency to add
      #   @return [:runtime, :depenncy]
      #   @api private
      #
      # @!attribute [r] gem_name
      #   The name of the gem to add a dependency on (i.e. 'rubocop')
      #   @return [String]
      #   @api private
      #
      # @!attribute [r] version_constraint
      #   The version constraint for the gem (i.e. '~> 2.1')
      #   @return [String]
      #   @api private
      #
      # @!attribute [r] force
      #   Whether to update the dependency even if the type is different
      #   @return [Boolean]
      #   @api private
      #
      # @!attribute [r] receiver_name
      #   The name of the receiver for the Gem::Specification block
      #
      #    i.e. 'spec' in `spec.add_dependency 'rubocop', '~> 1.0'`
      #
      #   @return [Symbol]
      #   @api private
      #
      # @!attribute [r] found_gemspec_block
      #   Whether the Gem::Specification block was found in the gemspec file
      #
      #   Only valid after calling `#call`.
      #   @return [Boolean]
      #   @api private
      #
      # @!attribute [r] found_dependencies
      #   The dependencies found in the gemspec file
      #
      #   Only valid after calling `#call`.
      #   @return [Array<Hash>]
      #   @api private
      #
      # @api public
      class UpsertDependency < Parser::TreeRewriter # rubocop:disable Metrics/ClassLength
        # Create a new instance of a dependency upserter
        # @example
        #   add_dependency = Bundler::GemBytes::Gemspec::UpsertDependency.new(:runtime, 'my_gem', '~> 1.0')
        # @param dependency_type [Symbol] The type of dependency to add
        # @param gem_name [String] The name of the gem to add a dependency on
        # @param version_constraint [String] The version constraint for the gem
        # @param force [Boolean] Whether to update the dependency even if the type is different
        def initialize(dependency_type, gem_name, version_constraint, force: false)
          super()

          self.dependency_type = dependency_type
          @gem_name = gem_name
          self.version_constraint = version_constraint
          @force = force

          @found_dependencies = []
        end

        # Returns the content of the gemspec file with the new/updated dependency
        #
        # @param code [String] The content of the gemspec file
        #
        # @return [String] The updated gemspec content with the new/added dependency
        #
        # @raise [ArgumentError] if the Gem Specification block is not found in the given gemspec
        #
        # @example
        #   code = File.read('project.gemspec')
        #   add_dependency = Bundler::GemBytes::AddDependency.new(:runtime, 'my_gem', '~> 1.0')
        #   updated_code = add_dependency.call(code)
        #   puts updated_code
        #
        #
        def call(code)
          ast = RuboCop::AST::ProcessedSource.new(code, ruby_version).ast
          buffer = Parser::Source::Buffer.new('(string)', source: code)
          @found_gemspec_block = false
          rewrite(buffer, ast).tap do |_result|
            raise ArgumentError, 'Gem::Specification block not found' unless found_gemspec_block
          end
        end

        attr_reader :dependency_type, :gem_name, :version_constraint, :force,
                    :receiver_name, :found_gemspec_block, :found_dependencies

        # Handles block nodes within the AST to locate the Gem Specification block
        #
        # @param node [Parser::AST::Node] The block node within the AST
        # @return [void]
        # @api private
        def on_block(node)
          return if receiver_name # already processing the Gem Specification block

          @found_gemspec_block = true
          @receiver_name = gem_specification_pattern.match(node)

          return unless receiver_name

          super # process the children of this node to find the existing dependencies

          upsert_dependency(node)

          @receiver_name = nil
        end

        # Handles `send` nodes within the AST to locate dependency calls
        #
        # If receiver_name is not present then we are not in a Gem Specification block.
        #
        # @param node [Parser::AST::Node] The `send` node to check for dependency patterns
        # @return [void]
        # @api private
        def on_send(node)
          return unless receiver_name.present?
          return unless (match = dependency_pattern.match(node))

          found_dependencies << { node:, match: }
        end

        private

        # Adds or updates the given dependency in the Gem::Specification block
        # @param node [Parser::AST::Node] The block node within the AST
        # @return [void]
        # @api private
        def upsert_dependency(node)
          if found_dependencies.empty?
            add_dependency(node)
          else
            update_dependency
          end
        end

        # Adds a new dependency to the Gem::Specification block
        # @param node [Parser::AST::Node] The Gem::Specification block node within the AST
        # @return [void]
        # @api private
        def add_dependency(node)
          insert_after(node.children[2].children.last.loc.expression, "\n  #{dependency_source_code}")
        end

        # The dependency type (:runtime or :development) based on a given method name
        # @param method [Symbol] The method name to convert to a dependency type
        # @return [Symbol] The dependency type
        # @api private
        def dependency_method_to_type(method)
          method == :add_development_dependency ? :development : :runtime
        end

        # Error message for a dependency type conflict
        # @param node [Parser::AST::Node] The existing dependency node
        # @return [String] The error message
        # @api private
        def dependency_type_conflict_error(node)
          <<~MESSAGE.chomp.gsub("\n", ' ')
            Trying to add a
            #{dependency_method_to_type(dependency_type_method).upcase}
            dependency on "#{gem_name}" which conflicts with the existing
            #{dependency_method_to_type(node.children[1]).upcase}
            dependency.
            Pass force: true to update dependencies where the
            dependency type is different.
          MESSAGE
        end

        # Checks if the given dependency type conflicts with the existing dependency type
        #
        # Returns false if {#force} is true.
        #
        # @param dependency_node [Parser::AST::Node] The existing dependency node
        # @return [Boolean] Whether the dependency type conflicts
        # @api private
        def dependency_type_conflict?(dependency_node)
          dependency_node.children[1] != dependency_type_method && !force
        end

        # The source code for the updated dependency declaration
        # @param existing_dependency_node [Parser::AST::Node] The existing dependency node
        # @return [String] The source code for the dependency declaration
        # @api private
        def dependency_source_code(existing_dependency_node = nil)
          # Use existing quote character for string literals
          q = existing_dependency_node ? existing_dependency_node.children[3].loc.expression.source[0] : "'"
          "#{receiver_name}.#{dependency_type_method} #{q}#{gem_name}#{q}, #{q}#{version_constraint}#{q}"
        end

        # Replaces the existing dependency node with the updated dependency declaration
        # @param dependency_node [Parser::AST::Node] The existing dependency node
        # @return [void]
        # @api private
        def replace_dependency_node(dependency_node)
          replace(dependency_node.loc.expression, dependency_source_code(dependency_node))
        end

        # Updates the found_dependencies from the Gem::Specification block
        # @return [void]
        # @api private
        def update_dependency
          found_dependencies.each do |found_dependency|
            dependency_node = found_dependency[:node]
            raise(dependency_type_conflict_error(dependency_node)) if dependency_type_conflict?(dependency_node)

            replace_dependency_node(dependency_node)
          end
        end

        # Validates and sets the dependency type
        # @param dependency_type [Symbol] The type of dependency to add (must be :runtime or :development)
        # @raise [ArgumentError] if the dependency type is not :runtime or :development
        # @return [Symbol] The dependency type
        # @api private
        def dependency_type=(dependency_type)
          unless %i[runtime development].include?(dependency_type)
            raise(
              ArgumentError,
              "Invalid dependency type: #{dependency_type.inspect}"
            )
          end
          @dependency_type = dependency_type
        end

        # Validates and sets the version constraint
        # @param version_constraint [String] The version constraint to set
        # @raise [ArgumentError] if the version constraint is invalid
        # @return [String] The version constraint
        # @api private
        def version_constraint=(version_constraint)
          begin
            Gem::Requirement.new(version_constraint)
            true
          rescue Gem::Requirement::BadRequirementError
            raise ArgumentError, "Invalid version constraint: #{version_constraint.inspect}"
          end
          @version_constraint = version_constraint
        end

        # Returns the Ruby version in use as a float (MAJOR.MINOR only)
        # @return [Float] The Ruby version number, e.g., 3.0
        # @api private
        def ruby_version = RUBY_VERSION.match(/^(?<version>\d+\.\d+)/)['version'].to_f

        # Determines the dependency method based on the dependency type
        # @return [Symbol] Either :add_development_dependency or :add_dependency
        # @api private
        def dependency_type_method
          dependency_type == :development ? :add_development_dependency : :add_dependency
        end

        # The patter to match a dependency declaration in the AST
        # @return [RuboCop::AST::NodePattern] The dependency pattern
        # @api private
        def dependency_pattern
          @dependency_pattern ||=
            RuboCop::AST::NodePattern.new(<<~PATTERN)
              (send
                { (send _ :#{receiver_name}) | (lvar :#{receiver_name}) }
                ${ :add_dependency :add_runtime_dependency :add_development_dependency }
                (str #{gem_name ? "$\"#{gem_name}\"" : '$_gem_name'})
                <(str $_version_constraint) ...>
              )
            PATTERN
        end

        # The pattern to match the Gem::Specification block in the AST
        # @return [RuboCop::AST::NodePattern] The Gem::Specification pattern
        # @api private
        def gem_specification_pattern
          @gem_specification_pattern ||=
            RuboCop::AST::NodePattern.new(<<~PATTERN)
              (block (send (const (const nil? :Gem) :Specification) :new)(args (arg $_)) ...)
            PATTERN
        end
      end
    end
  end
end
