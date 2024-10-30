# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Actions do
  let(:including_class) do
    Class.new do
      include Bundler::GemBytes::Actions
    end
  end

  let(:instance) { including_class.new }

  # More detailed tests of add_dependency are in the tests for UpsertDependency
  # class.
  #
  # These tests just make sure that calls to add_dependency are correctly delegated
  # to the UpsertDependency class.
  #
  describe '.add_dependency' do
    subject { instance.add_dependency(dependency_type, gem_name, version_constraint, force:) }

    let(:dependency_type) { :development }
    let(:gem_name) { 'rspec' }
    let(:version_constraint) { '~> 3.13' }
    let(:force) { false }

    it 'adds the dependency to the gemspec' do
      # Make a temporary directory to work in
      Dir.mktmpdir do |temp_dir|
        Dir.chdir(temp_dir) do
          # Create a new gemspec file
          gemspec_file = 'my_gem.gemspec'
          File.write(gemspec_file, <<~GEMSPEC)
            Gem::Specification.new do |spec|
              spec.name = 'my_gem'
              spec.version = '0.1.0'
            end
          GEMSPEC

          # Add the dependency
          instance.add_dependency(dependency_type, gem_name, version_constraint, force: force)

          # Read the gemspec file
          gemspec_content = File.read(gemspec_file)

          # Check that the dependency was added
          expect(gemspec_content).to include("spec.add_development_dependency 'rspec', '~> 3.13'")
        end
      end
    end
  end
end
