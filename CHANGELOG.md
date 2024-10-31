# Changelog

All notable changes to the process_executer gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
