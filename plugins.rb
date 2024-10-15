# frozen_string_literal: true

require 'bundler/gem_bytes'

# Register Bundler::GemBytes::BundlerCommand as the handler for the `gem-bytes`
# bundler command

Bundler::Plugin::API.command('gem-bytes', Bundler::GemBytes::BundlerCommand)
