# frozen_string_literal: true

require 'forwardable'
require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Actions
      # Updates a gemspec according to the given block
      #
      # This class enables you to programmatically update a gemspec file by adding or
      # removing dependencies, updating configuration parameters, and manipulating
      # metadata. It processes the gemspec file as an Abstract Syntax Tree (AST),
      # which allows granular control over gemspec updates.
      #
      # Key terms:
      # * `gemspec_block`: The AST node representing the Gem::Specification block in
      #   the gemspec file.
      # * `receiver_name`: The receiver of the Gem::Specification block (e.g., 'spec'
      #   in `spec.add_dependency`).
      # * `dependency declarations`: Calls to methods like `add_dependency` or
      #   `add_runtime_dependency` within the gemspec.
      #
      # @example
      #   gemspec_path = Dir['*.gemspec'].first
      #   gemspec_content = File.read(gemspec_path)
      #   updated_gemspec_content = Gemspec.new.call(gemspec_content, path: gemspec_path) do
      #     add_dependency 'activesupport', '~> 7.0'
      #     add_runtime_dependency 'process_executer', '~> 1.1'
      #     add_development_dependency 'rubocop', '~> 1.68'
      #     remove_dependency 'byebug'
      #     config 'required_ruby_version', '>= 2.5.0'
      #     remove_config 'required_ruby_version'
      #     config_metadata 'homepage', 'https://example.com'
      #     remove_config_metadata 'homepage'
      #   end
      #
      # @api public
      #
      class Gemspec < Parser::TreeRewriter
        extend Forwardable

        # Create a new Gemspec action
        #
        # @example
        #   Gemspec.new(context: self)
        # @param context [Bundler::GemBytes::ScriptExecuter] The context in which the action is being run
        #
        def initialize(context:)
          @context = context
          super()
        end

        def_delegators :data, :attributes, :dependencies, :gemspec_ast, :gemspec_object,
                       :gemspec_object_name, :source, :source_path, :source_ast, :source_buffer

        # Processes the given gemspec file and returns the updated content
        #
        # @example
        #   updated_gemspec_content = Gemspec.new.call(gemspec_content, source_path: gemspec_path) do
        #     add_dependency 'activesupport', '~> 7.0'
        #   end
        # @param code [String] The content of the gemspec file
        # @param path [String] The path to the gemspec file (used for error reporting)
        # @return [String] The updated gemspec file content
        # @raise [ArgumentError] if the Gem Specification block is not found in the given gemspec content
        #
        def call(source, source_path: '(string)', &action_block)
          @data = GemSpecification.new(source, source_path)
          @action_block = action_block
          @processing_gemspec_block = false
          rewrite(source_buffer, source_ast).tap do |_result|
            raise ArgumentError, 'Gem::Specification block not found' unless gemspec_ast.present?
          end
        end

        # The ScriptExecuter object that called this action (used for testing)
        # @return [Bundler::GemBytes::ScriptExecuter]
        # @api private
        attr_reader :context

        # Indicates that the gemspec block was found and is being processed
        # @return [Boolean]
        # @api private
        attr_reader :processing_gemspec_block

        # The block passed to #call containing the instructions to update the gemspec
        # @return [Proc]
        # @api private
        attr_reader :action_block

        # The GemSpecification object containing information about the gemspec file
        # @return [GemSpecification]
        # @api private
        attr_reader :data

        alias processing_gemspec_block? processing_gemspec_block

        # Handles block nodes within the AST to locate the Gem Specification block
        #
        # @param node [Parser::AST::Node] The block node within the AST
        # @return [void]
        # @api private
        def on_block(node)
          # If already processing the Gem Specification block, this must be some other nested block
          return if processing_gemspec_block?

          data.gemspec_object_name = gem_specification_pattern.match(node)

          return unless gemspec_object_name

          @processing_gemspec_block = true
          data.gemspec_ast = node

          super # process the children of this node to find interesting parts of the Gem::Specification block

          @processing_gemspec_block = false

          # Call the action_block to do requested modifications the Gem::Specification block.
          # The default receiver in the block is this object.
          # receiver_name and gem_specification are passed as arguments.
          return unless action_block

          instance_exec(gemspec_object_name, gemspec_object, &action_block)
        end

        # Handles `send` nodes within the AST to locate dependency calls
        #
        # Only processes `send` nodes within the Gem::Specification block.
        #
        # @param node [Parser::AST::Node] The `send` node to check for dependency patterns
        # @return [void]
        # @api private
        def on_send(node)
          return unless processing_gemspec_block?

          handle_dependency(node) || handle_attribute(node)
        end

        # Removes a dependency from the Gem::Specification block
        #
        # @example
        #   remove_dependency 'rubocop'
        #   # Removes the dependency on 'rubocop' from the Gem::Specification block:
        #   # spec.add_development_dependency 'rubocop', '~> 1.68'
        # @param gem_name [String] the name of the gem to remove a dependency on
        # @return [void]
        #
        # TODO: just pass data to DeleteDependency.new
        def remove_dependency(gem_name)
          DeleteDependency.new(self, gemspec_ast, gemspec_object_name, dependencies).call(gem_name)
        end

        # Adds or updates a dependency to the Gem::Specification block
        #
        # @example
        #   add_dependency 'rails', '~> 7.0'
        #   # Adds (or updates) the following line to the Gem::Specification block:
        #   # spec.add_dependency 'rails', '~> 7.0'
        # @param gem_name [String] the name of the gem to add a dependency on
        # @param version_constraints [Array[String]] one or more version constraints on the gem
        # @param method_name [String] the name of the method to use to add the dependency
        # @return [void]
        #
        # TODO: just pass data to DeleteDependency.new
        def add_dependency(gem_name, *version_constraints, method_name: :add_dependency)
          new_dependency = Dependency.new(method_name, gem_name, version_constraints)
          UpsertDependency.new(self, gemspec_ast, gemspec_object_name, dependencies).call(new_dependency)
        end

        # Adds or updates a dependency to the Gem::Specification block
        #
        # @example
        #   add_runtime_dependency 'rails', '~> 7.0'
        #   # Adds (or updates) the following line to the Gem::Specification block:
        #   # spec.add_runtime_dependency 'rails', '~> 7.0'
        # @param gem_name [String] the name of the gem to add a dependency on
        # @param version_constraint [String] the version constraint on the gem
        # @return [void]
        #
        def add_runtime_dependency(gem_name, version_constraint)
          add_dependency(gem_name, version_constraint, method_name: :add_runtime_dependency)
        end

        # Adds or updates a development dependency to the Gem::Specification block
        #
        # @example
        #   add_runtime_development_dependency 'rubocop', '~> 1.68'
        #   # Adds (or updates) the following line to the Gem::Specification block:
        #   # spec.add_development_dependency 'rubocop', '~> 1.68'
        # @param gem_name [String] the name of the gem to add a dependency on
        # @param version_constraint [String] the version constraint on the gem
        # @return [void]
        #
        def add_development_dependency(gem_name, version_constraint)
          add_dependency(gem_name, version_constraint, method_name: :add_development_dependency)
        end

        private

        # Save the dependency if the node is a dependency
        # @param node [Parser::AST::Node] the node to check if it is a dependency
        # @return [Boolean] true if the node is a dependency, false otherwise
        # @api private
        def handle_dependency(node)
          return false unless (match = dependency_pattern.match(node))

          dependencies << DependencyNode.new(node, Dependency.new(*match))

          true
        end

        # Save the attribute if the node is an attribute
        # @param node [Parser::AST::Node] the node to check if it is an attribute
        # @return [Boolean] true if the node is an attribute, false otherwise
        # @api private
        def handle_attribute(node)
          return false unless (match = attribute_pattern.match(node))
          return false unless match[0].end_with?('=')

          name = match[0][0..-2]
          value = match[1]
          attributes << AttributeNode.new(node, Attribute.new(name, value))

          true
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

        # The pattern to match a dependency declaration in the AST
        # @return [RuboCop::AST::NodePattern] The dependency pattern
        # @api private
        def dependency_pattern
          # :nocov: JRuby give false positive for this line being uncovered by tests
          @dependency_pattern ||=
            RuboCop::AST::NodePattern.new(<<~PATTERN)
              (send
                { (send _ :#{gemspec_object_name}) | (lvar :#{gemspec_object_name}) }
                ${ :add_dependency :add_runtime_dependency :add_development_dependency }
                (str $_gem_name)
                <(str $_version_constraint) ...>
              )
            PATTERN
          # :nocov:
        end

        # The pattern to match an attribute in the AST
        # @return [RuboCop::AST::NodePattern] The attribute pattern
        # @api private
        def attribute_pattern
          # :nocov: JRuby give false positive for this line being uncovered by tests
          @attribute_pattern ||=
            RuboCop::AST::NodePattern.new(<<~PATTERN)
              (send
                (lvar :#{gemspec_object_name}) $_name $_value
              )
            PATTERN
          # :nocov:
        end
      end
    end
  end
end

require_relative 'gemspec/attribute'
require_relative 'gemspec/attribute_node'
require_relative 'gemspec/gem_specification'
require_relative 'gemspec/delete_dependency'
require_relative 'gemspec/dependency'
require_relative 'gemspec/dependency_node'
require_relative 'gemspec/upsert_dependency'
