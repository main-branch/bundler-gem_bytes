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
add_dependency :development, "rubocop", "~> 1.6"
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
