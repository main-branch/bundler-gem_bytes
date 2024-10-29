# frozen_string_literal: true

require 'thor'
require_relative 'actions'

module Bundler
  module GemBytes
    # ScriptExecutor is responsible for executing scripts using Thor actions
    #
    # @api public
    #
    # @example Executing a script from a file or URI
    #   executor = Bundler::GemBytes::ScriptExecutor.new
    #   executor.execute('path_or_uri_to_script')
    class ScriptExecutor < ::Thor::Group
      include ::Thor::Actions
      include Bundler::GemBytes::Actions

      # Set the source paths for Thor to use
      # @return [Array<String>] the source paths
      # @api private
      def self.source_paths
        # Add the current working directory or the directory of the script
        [Dir.pwd]
      end

      # Executes the script from a URI or file path
      #
      # @param path_or_uri [String] the URI or file path to the script
      # @return [void]
      # @raise [RuntimeError] if the script cannot be loaded
      # @example Execute a script from a path
      #   execute('path/to/script.rb')
      def execute(path_or_uri)
        apply(path_or_uri)
      rescue StandardError => e
        raise "Failed to execute script from #{path_or_uri}: #{e.message}"
      end
    end
  end
end
