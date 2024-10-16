# frozen_string_literal: true

module Bundler
  module GemBytes
    # A bundler command that adds features to your existing Ruby Gems project
    #
    # See [our repository of templates](http://gembytes.com/templates) for adding
    # testing, linting, and security frameworks to your project.
    #
    # @api public
    #
    class BundlerCommand < Bundler::Plugin::API
      # Called when the `gem-bytes` command is invoked
      #
      # @example
      #   $ bundler gem-bytes URI_OR_PATH
      #
      # @param command [String] the command that was invoked (in this case, 'gem-bytes')
      # @param args [Array<String>] any additional arguments passed to the command
      #
      # @raise [BundlerError] if there was an error executing the command
      # @return [void]
      #
      def exec(_command, args)
        uri_or_path = validate_args(args)
        script_content = load_script(uri_or_path)
        puts script_content
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

      # Loads the script content from the provided URI or file path
      #
      # @param uri_or_path [String] the URI or file path to load the script from
      # @raise [SystemExit] if there is an error loading the script
      # @return [String] the content of the script
      # @api private
      def load_script(uri_or_path)
        loader = ScriptLoader.new(uri_or_path)
        loader.load
      rescue RuntimeError => e
        warn "Error loading script: #{e.message}"
        exit 1
      end
    end
  end
end
