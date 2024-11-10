# frozen_string_literal: true

require 'bundler'

module Bundler
  module GemBytes
    # A bundler command that adds features to your existing Ruby Gems project
    # @api public
    class BundlerCommand < Bundler::Plugin::API
      # Executes the `gem-bytes` command
      #
      # @example
      #   BundlerCommand.new.exec('gem-bytes', ['uri_or_path', *extra_args])
      # @param _command [String] the invoked bundler command (in this case, 'gem-bytes')
      # @param args [Array<String>] command arguments
      # @raise [SystemExit] if an error occurs
      # @return [void]
      def exec(_command, args)
        uri_or_path = validate_args(args)
        execute_script(uri_or_path)
      end

      private

      # Validates that exactly one argument is provided
      #
      # @param args [Array<String>] the arguments passed to the command
      # @raise [SystemExit] if the argument count is not correct
      # @return [String] the validated URI or file path
      # @api private
      def validate_args(args)
        if args.size != 1
          warn 'Error: You must provide exactly one argument, either a file path or URI.'
          exit 1
        end
        args.first
      end

      # Executes the script using ScriptExecutor
      #
      # @param uri_or_path [String] the URI or file path to the script
      # @return [void]
      # @api private
      def execute_script(uri_or_path)
        executor = ScriptExecutor.new
        executor.execute(uri_or_path)
      rescue RuntimeError => e
        warn "Error applying script: #{e.message}"
        exit 1
      end
    end
  end
end
