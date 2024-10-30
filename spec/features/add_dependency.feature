Feature: Add or update a dependency to the project's gemspec

  Scenario: Add a dependency

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
      add_dependency :runtime, 'foo', '>= 1.0'
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
      add_dependency :runtime, 'foo', '>= 1.0'
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
      add_dependency :runtime, 'foo', '>= 1.0'
      """
    When I run "bundle gem-bytes gem_bytes_script"
    Then the command should have failed
    And the command stderr should contain "the dependency type is different"
