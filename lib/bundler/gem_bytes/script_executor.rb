# frozen_string_literal: true

require 'thor'
require_relative 'actions'

module Bundler
  module GemBytes
    # Responsible for executing scripts using Thor and GemBytes actions
    #
    # This class enables the execution of scripts from a file or URI, integrating
    # with `Thor::Actions` to allow advanced file manipulation and action chaining.
    # This can be particularly useful for tasks like creating or modifying files,
    # managing dependencies, and implementing workflows for gem development.
    #
    # @example Executing a script from a file or URI
    #   executor = Bundler::GemBytes::ScriptExecutor.new
    #   executor.execute('path_or_uri_to_script')
    # @api public
    class ScriptExecutor < ::Thor::Group
      include ::Thor::Actions
      include Bundler::GemBytes::Actions

      # Sets the source paths for `Thor::Actions`
      #
      # This determines where action scripts will be sourced from.
      #
      # By default, the source path is set to the current working directory, which
      # allows scripts to access files from the local file system during execution.
      #
      # @return [Array<String>] the list of source paths
      #
      # @api private
      def self.source_paths
        [Dir.pwd]
      end

      # Executes a script from a given URI or file path
      #
      # This method loads the script located at the specified `path_or_uri` and
      # executes it within the context of this class which includes `Thor::Actions`
      # and `Bundler::GemBytes::ScriptExecutor`. This allows the script to perform
      # tasks such as modifying files, creating directories, and other common file
      # system operations.
      #
      # @param path_or_uri [String] the URI or file path to the script
      #
      # @return [void]
      #
      # @raise [RuntimeError] if the script cannot be loaded
      #
      # @example Execute a script from a path
      #   execute('path/to/script.rb')
      #
      def execute(path_or_uri)
        apply(path_or_uri)
      rescue StandardError => e
        raise "Failed to execute script from #{path_or_uri}: #{e.message}"
      end
    end
  end
end
