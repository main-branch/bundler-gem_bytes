# frozen_string_literal: true

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
      # @!attribute [r] code
      #    The contents of the gemspec file passed to #call
      #
      #    @return [String]
      #    @api private
      #
      # @!attribute [r] action_block
      #   The block passed to #call containing the instructions to update the gemspec
      #
      #   @return [Proc]
      #   @api private
      #
      # @!attribute [r] receiver_name
      #   The name of the receiver for the Gem::Specification block
      #
      #    i.e. 'spec' in `spec.add_dependency 'rubocop', '~> 1.0'`
      #
      #   Only valid after calling `#call`. Returns nil if the receiver was not found.
      #
      #   @return [Symbol, nil]
      #   @api private
      #
      # @!attribute [r] gemspec_block
      #   The AST node representing the Gem::Specification block
      #
      #   Only valid after calling `#call`. Returns nil if the block was not found.
      #
      #   @return [Parser::AST::Node, nil]
      #   @api private
      #
      # @!attribute [r] dependencies
      #   The dependency declarations found in the gemspec file
      #
      #   Only valid after calling `#call`. Returns an empty array if no dependencies were found.
      #
      #   @return [Array<Dependency>]
      #   @api private
      #
      # @!attribute [r] context
      #   The actions object that called this action (used for testing)
      #
      #   @return [Array<Dependency>]
      #   @api private
      #
      # @!attribute [r] processing_gemspec_block
      #   Indicates that the gemspec block was found and is being processed
      #
      #   @return [Boolean]
      #   @api private
      #
      # @api public
      #
      class Gemspec < Parser::TreeRewriter
        # Create a new Gemspec action
        #
        # @example
        #   Gemspec.new(context: self)
        # @param context [Bundler::GemBytes::Actions] The context in which the action is being run (for testing)
        #
        def initialize(context:)
          @context = context
          super()
          initialize_private_attrs
        end

        # Processes the given gemspec file and returns the updated content
        #
        # @example
        #   updated_gemspec_content = Gemspec.new.call(gemspec_content, path: gemspec_path) do
        #     add_dependency 'activesupport', '~> 7.0'
        #   end
        # @param code [String] The content of the gemspec file
        # @param path [String] The path to the gemspec file (used for error reporting)
        # @return [String] The updated gemspec file content
        # @raise [ArgumentError] if the Gem Specification block is not found in the given gemspec content
        #
        def call(code, path: '(string)', &action_block)
          initialize_private_attrs
          @code = code
          @action_block = action_block
          buffer, ast = parse(code, path)
          rewrite(buffer, ast).tap do |_result|
            raise ArgumentError, 'Gem::Specification block not found' unless gemspec_block.present?
          end
        end

        attr_reader :receiver_name, :gemspec_block, :dependencies,
                    :processing_gemspec_block, :action_block, :code,
                    :context

        alias processing_gemspec_block? processing_gemspec_block

        # The currently running Ruby version as a float (MAJOR.MINOR only)
        #
        # @return [Float] The Ruby version number, e.g., 3.0
        # @api private
        def ruby_version = RUBY_VERSION.match(/^(?<version>\d+\.\d+)/)['version'].to_f

        # Handles block nodes within the AST to locate the Gem Specification block
        #
        # @param node [Parser::AST::Node] The block node within the AST
        # @return [void]
        # @api private
        def on_block(node)
          # If already processing the Gem Specification block, this must be some other nested block
          return if processing_gemspec_block?

          @receiver_name = gem_specification_pattern.match(node)

          return unless receiver_name

          @processing_gemspec_block = true
          @gemspec_block = node

          super # process the children of this node to find interesting parts of the Gem::Specification block

          @processing_gemspec_block = false

          # Call the action_block to do requested modifications the Gem::Specification block.
          # The default receiver in the block is this object.
          # receiver_name and load_gemspec are passed as arguments.
          instance_exec(receiver_name, load_gemspec, &action_block) if action_block
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
          return unless (match = dependency_pattern.match(node))

          dependencies << DependencyNode.new(node, Dependency.new(*match))
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
        def remove_dependency(gem_name)
          DeleteDependency.new(self, gemspec_block, receiver_name, dependencies).call(gem_name)
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
        def add_dependency(gem_name, *version_constraints, method_name: :add_dependency)
          new_dependency = Dependency.new(method_name, gem_name, version_constraints)
          UpsertDependency.new(self, gemspec_block, receiver_name, dependencies).call(new_dependency)
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

        # Initializes the private attributes of the Gemspec action
        #
        # This is done from #initialize and at the beginning of #call
        #
        # @return [void]
        # @api private
        def initialize_private_attrs
          # Used internally during #call
          @processing_gemspec_block = false

          # Supplied to #call
          @code = nil
          @action_block = nil

          # Valid after calling #call
          @receiver_name = nil
          @gemspec_block = nil
          @dependencies = []
        end

        # Load the gemspec file into a Gem::Specification object
        # @return [Gem::Specification] The Gem::Specification object
        # @api private
        def load_gemspec
          # Store the current $LOAD_PATH
          original_load_path = $LOAD_PATH.dup

          # Temporarily add 'lib' to the $LOAD_PATH
          lib_path = File.expand_path('lib', Dir.pwd)
          $LOAD_PATH.unshift(lib_path)

          # Evaluate the gemspec file
          eval(code, binding, '.').tap do # rubocop:disable Security/Eval
            # Restore the original $LOAD_PATH
            $LOAD_PATH.replace(original_load_path)
          end
        end

        # Parses the given code into an AST
        # @param code [String] The code to parse
        # @param path [String] The path to the file being parsed (used for error messages only)
        # @return [Array<Parser::AST::Node, Parser::Source::Buffer>] The AST and buffer
        # @api private
        def parse(code, path)
          buffer = Parser::Source::Buffer.new(path, source: code)
          processed_source = RuboCop::AST::ProcessedSource.new(code, ruby_version, path)
          unless processed_source.valid_syntax?
            raise "Invalid syntax in #{path}\n#{processed_source.diagnostics.map(&:render).join("\n")}"
          end

          ast = processed_source.ast
          [buffer, ast]
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
                { (send _ :#{receiver_name}) | (lvar :#{receiver_name}) }
                ${ :add_dependency :add_runtime_dependency :add_development_dependency }
                (str $_gem_name)
                <(str $_version_constraint) ...>
              )
            PATTERN
          # :nocov:
        end
      end
    end
  end
end

require_relative 'gemspec/delete_dependency'
require_relative 'gemspec/dependency'
require_relative 'gemspec/dependency_node'
require_relative 'gemspec/upsert_dependency'
