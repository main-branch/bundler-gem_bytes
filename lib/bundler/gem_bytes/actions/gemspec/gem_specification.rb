# frozen_string_literal: true

module Bundler
  module GemBytes
    module Actions
      class Gemspec < Parser::TreeRewriter
        # Holds information about the gemspec file
        # @!attribute [r] gemspec_object
        # @api private
        class GemSpecification
          # Create a new GemSpecification object
          #
          # @param source [String] The contents of the gemspec file
          # @param source_path [String] The path to the gemspec file
          # @api private
          #
          def initialize(source, source_path)
            @source = source
            @source_path = source_path

            @dependencies = []
            @attributes = []

            @source_buffer, @source_ast = parse(source, source_path)
          end

          # The contents of the gemspec file
          # @example
          #   data.source # => "Gem::Specification.new do |spec|\n  spec.name = 'example'\nend"
          # @return [String]
          attr_reader :source

          # The path to the gemspec file (used for error reporting)
          # @example
          #   data.source_path # => "example.gemspec"
          # @return [String]
          attr_reader :soure_path

          # The source buffer used when updating the gemspec file
          # @return [Parser::Source::Buffer]
          # @api private
          attr_reader :source_buffer

          # The parsed AST for the gemspec file source
          # @example
          #   data.source_ast # => (send nil :puts)
          # @return [Parser::AST::Node]
          attr_reader :source_ast

          # The Gem::Specification object
          # @example
          #   data.gemspec_object # => #<Gem::Specification:0x00007f9b1b8b3f10>
          # @return [Gem::Specification]
          def gemspec_object
            @gemspec_object ||= load_gem_specification
          end

          # The name of the Gem::Specification object within the gemspec block
          # @example When the gemspec block starts `Gem::Specification.new do |spec|`
          #   data.gemspec_object_name # => :spec
          # @return [Symbol]
          attr_accessor :gemspec_object_name

          # The AST node for the Gem::Specification block within the source
          # @return [Parser::AST::Node]
          attr_accessor :gemspec_ast

          # The dependencies found in the gemspec file
          # @return [Array<Dependency>]
          attr_reader :dependencies

          # The attributes found in the gemspec file
          # @return [Array<Attribute>]
          attr_reader :attributes

          private

          # Parses the given code into an AST
          # @param source [String] The code to parse
          # @param source_path [String] The path to the file being parsed (used for error messages only)
          # @return [Array<Parser::AST::Node, Parser::Source::Buffer>] The AST and buffer
          # @api private
          def parse(source, source_path)
            source_buffer = Parser::Source::Buffer.new(source_path, source: source)
            processed_source = RuboCop::AST::ProcessedSource.new(source, ruby_version, source_path)
            unless processed_source.valid_syntax?
              raise "Invalid syntax in #{source_path}\n#{processed_source.diagnostics.map(&:render).join("\n")}"
            end

            source_ast = processed_source.ast
            [source_buffer, source_ast]
          end

          # The currently running Ruby version as a float (MAJOR.MINOR only)
          #
          # @return [Float] The Ruby version number, e.g., 3.0
          # @api private
          def ruby_version = RUBY_VERSION.match(/^(?<version>\d+\.\d+)/)['version'].to_f

          # Load the gemspec file into a Gem::Specification object
          # @return [Gem::Specification] The Gem::Specification object
          # @api private
          def load_gem_specification
            # Store the current $LOAD_PATH
            original_load_path = $LOAD_PATH.dup

            # Temporarily add 'lib' to the $LOAD_PATH
            lib_path = File.expand_path('lib', Dir.pwd)
            $LOAD_PATH.unshift(lib_path)

            # Evaluate the gemspec file
            eval(source, binding, '.').tap do # rubocop:disable Security/Eval
              # Restore the original $LOAD_PATH
              $LOAD_PATH.replace(original_load_path)
            end
          end
        end
      end
    end
  end
end
