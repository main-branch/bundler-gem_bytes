# frozen_string_literal: true

module Bundler
  module GemBytes
    # The namespec for classes that modify the gemspec file
    module Gemspec; end
  end
end

require_relative 'gemspec/delete_dependency'
require_relative 'gemspec/upsert_dependency'
