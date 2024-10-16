# frozen_string_literal: true

require 'uri'
require 'open-uri'

module Bundler
  module GemBytes
    # ScriptLoader is responsible for loading a script from either a URI or a local file
    #
    # @example Loading a script from a URI
    #   loader = Bundler::GemBytes::ScriptLoader.new('https://example.com/script.rb')
    #   script_content = loader.load
    #   puts script_content
    #
    # @example Loading a script from a local file
    #   loader = Bundler::GemBytes::ScriptLoader.new('local_script.rb')
    #   script_content = loader.load
    #   puts script_content
    class ScriptLoader
      # Initializes the ScriptLoader
      #
      # @param source [String] the URI reference or local path to the script
      # @param uri_opener [Proc] dependency injection for URI opening
      # @param file_system [File] dependency injection for file operations
      #
      # @example Initialize with a URI
      #   loader = Bundler::GemBytes::ScriptLoader.new('https://example.com/script.rb')
      #
      # @example Initialize with a file path
      #   loader = Bundler::GemBytes::ScriptLoader.new('local_script.rb')
      def initialize(source, uri_opener: ->(uri_string) { URI.open(uri_string) }, file_system: File)
        @source = source
        @uri_opener = uri_opener
        @file_system = file_system
      end

      # Loads the script content from either the URI or the file
      #
      # @return [String] the content of the script
      # @raise [RuntimeError] if the file or URI cannot be loaded
      #
      # @example Load from a URI
      #   loader = Bundler::GemBytes::ScriptLoader.new('https://example.com/script.rb')
      #   script_content = loader.load
      #
      # @example Load from a local file
      #   loader = Bundler::GemBytes::ScriptLoader.new('local_script.rb')
      #   script_content = loader.load
      def load
        if uri?(@source)
          load_from_uri(@source)
        else
          load_from_file(@source)
        end
      end

      private

      # Checks if the source is a valid URI
      #
      # @param source [String] the input string to check
      # @return [Boolean] true if the source is a valid URI, false otherwise
      # @api private
      def uri?(source)
        uri = URI.parse(source)
        !!uri.scheme
      rescue URI::InvalidURIError
        false
      end

      # Loads the content from a URI using URI.open
      #
      # @param uri_string [String] the URI to load the content from
      # @return [String] the content loaded from the URI
      # @raise [RuntimeError] if the request fails or the scheme is unsupported
      # @api private
      def load_from_uri(uri_string)
        @uri_opener.call(uri_string).read
      rescue StandardError => e
        raise "Failed to load script from URI: #{uri_string}, error: #{e.message}"
      end

      # Loads the content from a file
      #
      # @param filename [String] the file to load the content from
      # @return [String] the content of the file
      # @raise [RuntimeError] if the file does not exist
      # @api private
      def load_from_file(filename)
        raise "File not found: #{filename}" unless @file_system.exist?(filename)

        @file_system.read(filename)
      end
    end
  end
end
