# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'active_support/core_ext/object'

module Bundler
  module GemBytes
    module Gemspec
      # Delete a dependency in a gemspec file
      #
      # This class works by parsing the gemspec file into an AST and then walking the
      # AST to find the Gem::Specification block (via #on_block). Once the block is
      # found, AST within that block is walked to locate the dependency declarations
      # (via #on_send). Any dependency declaration that matches the given gem name is
      # collected into the found_dependencies array.
      #
      # Once the Gem::Specification block is fully processed, any dependencies on the
      # given gem are deleted from the gemspec source.
      #
      # If the dependency is not found, the gemspec source is returned unmodified.
      #
      # @example
      #   require 'bundler/gem_bytes'
      #
      #   delete_dependency = Bundler::GemBytes::Gemspec::DeleteDependency.new('test_tool')
      #
      #   gemspec_file = 'foo.gemspec'
      #   gemspec = File.read(gemspec_file)
      #   updated_gemspec = delete_dependency.call(gemspec, path: gemspec_file)
      #   File.write(gemspec_file, updated_gemspec)
      #
      # @!attribute [r] gem_name
      #   The name of the gem to add a dependency on (i.e. 'rubocop')
      #   @return [String]
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
      class DeleteDependency < Parser::TreeRewriter
        # Create a new instance of a dependency upserter
        # @example
        #   command = Bundler::GemBytes::Gemspec::DeleteDependency.new('my_gem')
        # @param gem_name [String] The name of the gem to add a dependency on
        def initialize(gem_name)
          super()

          @gem_name = gem_name

          @found_dependencies = []
        end

        # Returns the content of the gemspec file with the dependency deleted
        #
        # @param code [String] The content of the gemspec file
        # @param path [String] This should be the path to the gemspspec file
        #
        #   path is used to generate error messages only
        #
        # @return [String] The updated gemspec content with the dependency deleted
        #
        # @raise [ArgumentError] if the Gem Specification block is not found in the given gemspec
        #
        # @example
        #   code = File.read('project.gemspec')
        #   command = Bundler::GemBytes::DeleteDependency.new('my_gem')
        #   updated_code = command.call(code)
        #   puts updated_code
        #
        def call(code, path: '(string)')
          @found_gemspec_block = false
          rewrite(*parse(code, path)).tap do |_result|
            raise ArgumentError, 'Gem::Specification block not found' unless found_gemspec_block
          end
        end

        attr_reader :gem_name, :receiver_name, :found_gemspec_block, :found_dependencies

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

          delete_dependencies

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

        # Deletes any dependency on the given gem within the Gem::Specification block
        # @return [void]
        # @api private
        def delete_dependencies
          found_dependencies.each do |found_dependency|
            dependency_node = found_dependency[:node]
            remove(range_including_leading_spaces(dependency_node))
          end
        end

        # Returns the range of the dependency node including any leading spaces & newline
        # @param node [Parser::AST::Node] The node
        # @return [Parser::Source::Range] The range of the dependency node
        # @api private
        def range_including_leading_spaces(node)
          leading_spaces = leading_whitespace_count(node)
          range = node.loc.expression
          range.with(begin_pos: range.begin_pos - leading_spaces - 1, end_pos: range.end_pos)
        end

        # Returns the # of leading whitespace chars in the source line before the node
        # @param node [Parser::AST::Node] The node
        # @return [Integer] The number of leading whitespace characters
        # @api private
        def leading_whitespace_count(node)
          match_data = node.loc.expression.source_line.match(/^\s*/)
          match_data ? match_data[0].size : 0
        end

        # Returns the Ruby version in use as a float (MAJOR.MINOR only)
        # @return [Float] The Ruby version number, e.g., 3.0
        # @api private
        def ruby_version = RUBY_VERSION.match(/^(?<version>\d+\.\d+)/)['version'].to_f

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
                (str #{gem_name ? "$\"#{gem_name}\"" : '$_gem_name'})
                <(str $_version_constraint) ...>
              )
            PATTERN
          # :nocov:
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
