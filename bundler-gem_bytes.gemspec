# frozen_string_literal: true

require_relative 'lib/bundler/gem_bytes/version'

Gem::Specification.new do |spec|
  spec.name = 'bundler-gem_bytes'
  spec.version = Bundler::GemBytes::VERSION
  spec.authors = ['James Couball']
  spec.email = ['jcouball@yahoo.com']

  spec.summary = 'A bundler plugin that adds features to your existing Ruby Gems project'
  spec.description = <<~DESCRIPTION
    A bundler plugin that adds features to your existing Ruby Gems project.

    See [our repository of templates](http://gembytes.com/templates) for adding
    testing, linting, and security frameworks to your project.
  DESCRIPTION

  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  # Project links
  spec.homepage = "https://github.com/main-branch/#{spec.name}"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'main_branch_shared_rubocop_config'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.66'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-rspec', '~> 0.4'

  if RUBY_PLATFORM != 'java'
    spec.add_development_dependency 'redcarpet', '~> 3.5'
    spec.add_development_dependency 'yard', '~> 0.9'
    spec.add_development_dependency 'yardstick', '~> 0.9'
  end
end
