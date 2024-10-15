# bundler-gem_bytes gem

[![Gem Version](https://badge.fury.io/rb/bundler-gem_bytes.svg)](https://badge.fury.io/rb/bundler-gem_bytes)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/bundler-gem_bytes/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/bundler-gem_bytes/file/CHANGELOG.md)
[![Build Status](https://github.com/main-branch/bundler-gem_bytes/actions/workflows/continuous-integration.yml/badge.svg)](https://github.com/main-branch/bundler-gem_bytes/actions/workflows/continuous-integration.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/2468fc247e5d66fc179f/maintainability)](https://codeclimate.com/github/main-branch/bundler-gem_bytes/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2468fc247e5d66fc179f/test_coverage)](https://codeclimate.com/github/main-branch/bundler-gem_bytes/test_coverage)
[![Conventional
Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Slack](https://img.shields.io/badge/slack-main--branch/bundler--gem_bytes-yellow.svg?logo=slack)](https://main-branch.slack.com/archives/C07RKRKTLDT)

**NOTE: https://gembytes.com is not yet active. For now, you will have to bring your own URL.**

A bundler plugin that adds features to your existing Ruby Gems project.

See [our repository of templates](http://gembytes.com/templates) for adding testing,
linting, and security frameworks to your project.

* [Installation](#installation)
* [Usage](#usage)
* [Development](#development)
* [Contributing](#contributing)
  * [Commit message guidelines](#commit-message-guidelines)
  * [Pull request guidelines](#pull-request-guidelines)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add bundler-gem_bytes
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install bundler-gem_bytes
```

## Usage

Add a feature to your gem as follows:

1. Find a feature to add at http://gembytes.com/features and make a note of the
   feature URL
2. Run `bundle gem-bytes URL`
3. Test the changes made to your project.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run all the tests that will be run in the `continuous-integration`
workflow. You can also run `bin/console` for an interactive prompt that will allow
you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push git
commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

To install this bundler plugin from the source code, run the following command from
the project's root directory:

```shell
bundler plugin install --path . bundler-gem_bytes
```

and then run `bundler plugin list` to make sure it was installed correctly:

```shell
$ bundler plugin list
bundler-gem_bytes
-----
  gem-bytes

$
```

Once installed, the bundler plugin can be run with the following command:

```shell
bundler gem-bytes
```

To uninstall the plugin, run:

```shell
bundler uninstall bundler-gem_bytes
```

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

Everyone interacting in the Bundler::GemBytes project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/main-branch/bundler-gem_bytes/blob/main/CODE_OF_CONDUCT.md).
