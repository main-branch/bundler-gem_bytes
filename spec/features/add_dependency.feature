Feature: Runs a gembytes script

  Scenario: Add and remove a dependency

    Given a gem project named "foo" with the bundler-gem_bytes plugin installed
    And the project has a gemspec containing:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_dependency 'bar', '>= 0.9'
      end
      """
    And a gem-bytes script "gem_bytes_script" containing:
      """
      gemspec do |gemspec_name, gemspec|
        add_dependency 'baz', '>= 1.0'
      end
      """
    When I run "bundle gem-bytes gem_bytes_script"
    Then the command should have succeeded
    And the gemspec should contain:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_dependency 'bar', '>= 0.9'
        spec.add_dependency 'baz', '>= 1.0'
      end
      """

  Scenario: Update a dependency

    Given a gem project named "foo" with the bundler-gem_bytes plugin installed
    And the project has a gemspec containing:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_dependency 'foo', '>= 0.9'
      end
      """
    And a gem-bytes script "gem_bytes_script" containing:
      """
      gemspec do |gemspec_name, gemspec|
        add_dependency 'foo', '>= 1.0'
      end
      """
    When I run "bundle gem-bytes gem_bytes_script"
    Then the command should have succeeded
    And the gemspec should contain:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_dependency 'foo', '>= 1.0'
      end
      """

  Scenario: Update a dependency with conflicting dependency type

    Given a gem project named "foo" with the bundler-gem_bytes plugin installed
    And the project has a gemspec containing:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_runtime_dependency 'foo', '>= 0.9'
      end
      """
    And a gem-bytes script "gem_bytes_script" containing:
      """
      gemspec do |gemspec_name, gemspec|
        add_development_dependency 'foo', '>= 1.0'
      end
      """
    When I run "bundle gem-bytes gem_bytes_script"
    Then the command should have failed
    And the command stderr should contain "which conflicts with the existing RUNTIME dependency"

  Scenario: Update a gemspec

    Given a gem project named "foo" with the bundler-gem_bytes plugin installed
    And the project has a gemspec containing:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
      end
      """
    And a gem-bytes script "gem_bytes_script" containing:
      """
      gemspec do |gemspec_name, gemspec|
        add_dependency 'example', '~> 1.0'
      end
      """
    When I run "bundle gem-bytes gem_bytes_script"
    Then the command should have succeeded
    And the gemspec should contain:
      """
      Gem::Specification.new do |spec|
        spec.name = 'foo'
        spec.version = '1.0'
        spec.add_dependency 'example', '~> 1.0'
      end
      """
