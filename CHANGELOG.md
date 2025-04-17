# Changelog

All notable changes to the process_executer gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3](https://github.com/main-branch/bundler-gem_bytes/compare/v0.2.2...v0.2.3) (2025-04-17)


### Bug Fixes

* Do not trigger build workflows after merging to main or for release PRs ([aa7539c](https://github.com/main-branch/bundler-gem_bytes/commit/aa7539c344a900375597a707d1be2256bb19775c))

## [0.2.2](https://github.com/main-branch/bundler-gem_bytes/compare/v0.2.1...v0.2.2) (2025-04-16)


### Bug Fixes

* Automate commit-to-publish workflow version file path wrong ([4220bd4](https://github.com/main-branch/bundler-gem_bytes/commit/4220bd4428cc4841d56c65fb86540d9237b0944b))

## [0.2.1](https://github.com/main-branch/bundler-gem_bytes/compare/v0.2.0...v0.2.1) (2025-04-16)


### Features

* Add a gemspec action to make modification to a project gemspec ([d83d145](https://github.com/main-branch/bundler-gem_bytes/commit/d83d14598922fe8b54de12b92232e8cae6e6e668))
* Add the remove_dependency sub-action to the gemspec action ([ba1ff7b](https://github.com/main-branch/bundler-gem_bytes/commit/ba1ff7b8401ff7dd29c37f457da14452ce55c8f2))


### Bug Fixes

* Allow dependencies to have multiple version constraints ([4217151](https://github.com/main-branch/bundler-gem_bytes/commit/421715118af964e5e53ae35cda445e5b2dfd4f48))
* Automate commit-to-publish workflow ([3d018da](https://github.com/main-branch/bundler-gem_bytes/commit/3d018da4b2ac3caceaa81dd12a0b7771fc03db18))

## v0.2.0 (2024-10-30)

[Full Changelog](https://github.com/main-branch/bundler-gem_bytes/compare/v0.1.0..v0.2.0)

Changes since v0.1.0:

* 96829fd docs: update the releasing guidelines
* 25c57f9 feat: make #remove_dependency available for gembytes scripts
* b285af5 docs: add development debugging instructions in the README.md
* ea05a44 fix: output an informative error when the gemspec parsed is not valid Ruby
* 2147776 test: add fully integrated test that installs and runs gembytes via bundler
* ab907b4 test: exclude lines from test coverage due to JRuby false positives
* 03692ad feat: make #add_dependency available for gembytes scripts
* 5d41e08 chore: add Bundler::GemBytes::Actions module to extend the API for gembytes scripts
* 6f7be90 chore: add class to upsert a gem dependency into a gemspec
* cf1ab4f chore: rake clobber should remove the .bundle directory

## v0.1.0 (2024-10-17)

[Full Changelog](https://github.com/main-branch/bundler-gem_bytes/compare/ce13f25..v0.1.0)

Changes:

* b678393 feat: download and execute GemBytes script
* 88c3ee9 chore: add script loading to the bundler plugin
* afda321 chore: add bug tracker uri to gemspec
* fe40e6c feat: add the script loader class
* 83c8841 fix: correct the require for bindler/gem_bytes in bin/console
* 74a638a chore: implement bundler plugin
* ce13f25 chore: initial version
