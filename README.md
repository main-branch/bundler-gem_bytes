# bundler-gem_bytes gem

[![Gem
Version](https://badge.fury.io/rb/bundler-gem_bytes.svg)](https://badge.fury.io/rb/bundler-gem_bytes)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/bundler-gem_bytes/)
[![Change
Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/bundler-gem_bytes/file/CHANGELOG.md)
[![Build
Status](https://github.com/main-branch/bundler-gem_bytes/actions/workflows/continuous-integration.yml/badge.svg)](https://github.com/main-branch/bundler-gem_bytes/actions/workflows/continuous-integration.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/2468fc247e5d66fc179f/maintainability)](https://codeclimate.com/github/main-branch/bundler-gem_bytes/maintainability)
[![Test
Coverage](https://api.codeclimate.com/v1/badges/2468fc247e5d66fc179f/test_coverage)](https://codeclimate.com/github/main-branch/bundler-gem_bytes/test_coverage)
[![Conventional
Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Slack](https://img.shields.io/badge/slack-main--branch/bundler--gem_bytes-yellow.svg?logo=slack)](https://main-branch.slack.com/archives/C07RKRKTLDT)

This gem is a bundler plugin that can add testing, linting, and security frameworks
to a Ruby gem project.

This project is similar to [the RailsBytes project](https://railsbytes.com) which
helps add configuration to a Rails project.

GemBytes scripts are run via the `bundler gem-bytes` command:

```shell
bundler gem-bytes PATH_OR_URI
```

where `PATH_OR_URI` identifies a gem-bytes script.

See [the repository of GemBytes scripts](http://gembytes.com/scripts) for publicly
available GemBytes scripts.

**NOTE: [the GemBytes repository](https://gembytes.com) is not yet active. For now, you will have to bring your
own script**

* [Installation](#installation)
* [Usage](#usage)
  * [Example](#example)
  * [Handling Errors](#handling-errors)
* [Development](#development)
  * [How this gem works](#how-this-gem-works)
  * [Debugging](#debugging)
  * [Releasing](#releasing)
* [Contributing](#contributing)
  * [Commit message guidelines](#commit-message-guidelines)
  * [Pull request guidelines](#pull-request-guidelines)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

Install the `bundler gem-bytes` command as follows:

```shell
bundle plugin install bunder-gem_bytes
```

## Usage

The `bundler gem-bytes` command requires exactly one argument, which can either be a
file path or a URI to a script. The script will be loaded and executed within the
context of your project.

### Example

1. Find a template script for a feature you'd like to add to your gem and make a note
   of its URI.
2. Run `bundler gem-bytes PATH_OR_URI` where `PATH_OR_URI` is either a local file
   path or a remote URI.
3. The script will be executed to add the relevant feature to your project.

### Handling Errors

If the file or URI cannot be loaded, an error message will be printed to `stderr`,
and the command will exit with a status code of `1`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run all the tests that will be run in the `continuous-integration`
workflow. You can also run `bin/console` for an interactive prompt that will allow
you to experiment.

### How this gem works

1. The user runs the `bundler gem-bytes` command from the command line, passing the
   path or URL to a GemBytes script:

   ```shell
   bundler gem-bytes [SCRIPT]
   ```

2. The `plugins.rb` file (in the root directory of this project) defines
   `Bundler::GemBytes::BundlerCommand` class as the handler for the `gem-bytes`
   bundler command:

    ```ruby
    require 'bundler/gem_bytes'

    # Register Bundler::GemBytes::BundlerCommand as the handler for the `gem-bytes`
    # bundler command

    Bundler::Plugin::API.command('gem-bytes', Bundler::GemBytes::BundlerCommand)
    ```

3. Bundler invokes the gem-bytes plugin by creating an instance of
   `Bundler::GemBytes::BundlerCommand` and then calling `#exec(command, args)` on
   that instance. Where:

   * `command` is the bundler command given on the command line. It will always be
     "gem-bytes".
   * `args` is the array of any other arguments given on the command line after the
     command. In this case, we expect the script path or URI.

4. The `BundlerCommand` instance creates a `Bundler::GemBytes::ScriptExecutor`
   instance and calls `#execute(path_or_uri)` on that instance. This method in turn
   calls `Thor::Actions#apply(path_or_uri)` to load the external script and execute
   it in the context of the `ScriptExecutor` instance.

   The `#apply` method, part of the `Thor::Actions` module, loads and executes the
   script within the context of the `ScriptExecutor` instance.

   If an error occurs during script execution, `BundlerCommand` catches the error, outputs an error message to `stderr`, and exits with a status code of `1`.

5. The `ScriptExecutor` class provides the environment/binding in which the GemBytes
   script is executed, allowing the script to use instance methods and context from
   `ScriptExecutor`. In addition to core Ruby and Active Support, the API available
   to this script includes methods from both the
   [`Thor::Actions`](https://github.com/rails/thor/wiki/Actions) and
   `Bundler::GemBytes::Actions` modules, which provide utilities for file
   manipulation, template generation, and other tasks essential for script execution.

### Debugging

To debug this gem it is recommended that you create a test project and install
this plugin with bundler from source code as follows:

```shell
# 1. Create a temp directory for testing (from the root directory of the project)
mkdir temp
cd temp

# 2. Create an new, empty RubyGem project to test
BUNDLE_IGNORE_CONFIG=TRUE bundle gem foo --no-test --no-ci --no-mit --no-coc --no-linter --no-changelog
cd foo

# 3. Install the plugin from source
BUNDLE_IGNORE_CONFIG=TRUE bundle plugin install --path ../.. bundler-gem_bytes

# 4. Create a gembytes script to add a development dependency on rubocop
cat <<SCRIPT > gem_bytes_script.rb
gemspec do
  add_development_dependency "rubocop", "~> 1.68"
end
SCRIPT

# 5. Modify code, set breakpoints, or add binding.{irb|pry} calls to the source

# 6. Run the plugin
BUNDLE_IGNORE_CONFIG=TRUE bundle gem-bytes gem_bytes_script.rb

# Repeat 4 - 6 until satisified :)
```

### Releasing

To release a new version of this gem, run `create-github-release [TYPE]` where
TYPE is MAJOR, MINOR, or PATCH according to SemVer based on the changes that
have been made since the last release:

* MAJOR: changes that break compatibility with previous versions, such as removing a
  public method, changing a method signature, or modifying the expected behavior of a
  method.
* MINOR: changes that add new features, enhance existing features, or deprecate
  features in a backward-compatible way, such as adding a new method or improving
  performance without breaking existing functionality.
* PATCH: changes that fix bugs or make other small modifications that do not affect
  the API or alter existing functionality, such as fixing user-facing typos or
  updating user documentation.

This command must be run from the project root directory with a clean worktree on the
default branch.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/main-branch/bundler-gem_bytes. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of
conduct](https://github.com/main-branch/bundler-gem_bytes/blob/main/CODE_OF_CONDUCT.md).

### Commit message guidelines

All commit messages must follow the [Conventional Commits
standard](https://www.conventionalcommits.org/en/v1.0.0/). This helps us maintain a
clear and structured commit history, automate versioning, and generate changelogs
effectively.

To ensure compliance, this project includes:

* A git commit-msg hook that validates your commit messages before they are accepted.

  To activate the hook, you must have node installed and run `npm install`.

* A GitHub Actions workflow that will enforce the Conventional Commit standard as
  part of the continuous integration pipeline.

  Any commit message that does not conform to the Conventional Commits standard will
  cause the workflow to fail and not allow the PR to be merged.

### Pull request guidelines

All pull requests must be merged using rebase merges. This ensures that commit
messages from the feature branch are preserved in the release branch, keeping the
history clean and meaningful.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bundler::GemBytes project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/main-branch/bundler-gem_bytes/blob/main/CODE_OF_CONDUCT.md).

gemspec path do |spec_var, spec|
  add_runtime_dependency 'example', '~> 1.1', '>= 1.1.4'
  add_development_dependency "rubocop", "~> 1.68"

  remove_dependency "example"

  attr "description", "#{spec.description}. Enhanced by GemBytes."
  attr "author", ENV['USER']
  attr "files", "Dir['lib/**/*.rb'] + Dir['bin/*']", quote: false
  attr "authors", <% spec.authors %>.append('GemBytes').inspect, quote: false

  remove_attr "license"

  metadata "homepage_url", "https://github.com/example/"
  remove_metadata "wiki_uri"

  in_block("if RUBY_PLATFORM != 'java'", "end") do
    add_development_dependency 'redcarpet', '~> 3.5'
    add_development_dependency 'yard', '~> 0.9'
    add_development_dependency 'yardstick', '~> 0.9'
  end

  code <<~CODE
    if RUBY_PLATFORM != 'java'
      <%= spec_var %>.add_development_dependency 'redcarpet', '~> 3.5'
      <%= spec_var %>.add_development_dependency 'yard', '~> 0.9'
      <%= spec_var %>.add_development_dependency 'yardstick', '~> 0.9'
    end
  CODE
end
