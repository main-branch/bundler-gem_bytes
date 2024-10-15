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
      #   $ bundler gem-bytes
      #
      # @param command [String] the command that was invoked (in this case, 'gem-bytes')
      # @param args [Array<String>] any additional arguments passed to the command
      #
      # @raise [BundlerError] if there was an error executing the command
      # @return [void]
      #
      def exec(command, args)
        puts 'Hello from the gem-bytes bundler command'
        puts "You called #{command} with args: #{args.inspect}"
      end
    end
  end
end
