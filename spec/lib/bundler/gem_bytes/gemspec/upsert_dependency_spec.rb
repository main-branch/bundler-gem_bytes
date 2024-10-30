# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Gemspec::UpsertDependency do
  let(:instance) { described_class.new(dependency_type, gem_name, version_constraint, force:) }

  let(:dependency_type) { :development }
  let(:gem_name) { 'test_tool' }
  let(:version_constraint) { '~> 2.1' }
  let(:force) { false }

  describe '#initialize' do
    subject { instance }

    context 'with valid arguments' do
      let(:expected_attributes) do
        # :nocov: JRuby give false positive for this line being uncovered by tests
        {
          dependency_type: :development,
          gem_name: 'test_tool',
          version_constraint: '~> 2.1',
          force: false,
          found_dependencies: []
        }
        # :nocov:
      end

      it { is_expected.to have_attributes(expected_attributes) }
    end

    context 'when force is given as true' do
      let(:force) { true }
      let(:expected_attributes) { { force: true } }

      it { is_expected.to have_attributes(expected_attributes) }
    end

    context 'when dependency_type is invalid' do
      let(:dependency_type) { :invalid }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, 'Invalid dependency type: :invalid')
      end
    end

    context 'when the version constraint is invalid' do
      let(:version_constraint) { 'invalid' }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, 'Invalid version constraint: "invalid"')
      end
    end
  end

  describe '#call' do
    subject { instance.call(gemspec) }

    context 'when the gemspec does not contain a Gem::Specification block' do
      let(:gemspec) { <<~GEMSPEC }
        puts 'Hello, world!'
      GEMSPEC

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, 'Gem::Specification block not found')
      end
    end

    context 'when the gemspec has no dependencies' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.version = '0.1.0'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.version = '0.1.0'
            spec.add_development_dependency 'test_tool', '~> 2.1'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has dependencies but not the given one' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.version = '0.1.0'
          spec.add_dependency 'another_gem', '~> 1.3'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.version = '0.1.0'
            spec.add_dependency 'another_gem', '~> 1.3'
            spec.add_development_dependency 'test_tool', '~> 2.1'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency with the same type and version constraint' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.version = '0.1.0'
          spec.add_development_dependency 'test_tool', '~> 2.1'
        end
      GEMSPEC

      it 'is expected to not change the gemspec' do
        expect(subject).to eq(gemspec)
      end
    end

    context 'when the gemspec has the given dependency with a different version constraint' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.version = '0.1.0'
          spec.add_development_dependency 'test_tool', '~> 2.0'
        end
      GEMSPEC

      it 'is expected to update only the version constraint' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.version = '0.1.0'
            spec.add_development_dependency 'test_tool', '~> 2.1'
          end
        EXPECTED_GEMSPEC
      end

      context 'when the version constraint uses double quotes' do
        let(:gemspec) { <<~GEMSPEC }
          Gem::Specification.new do |spec|
            spec.name = "my_project"
            spec.version = "0.1.0"
            spec.add_development_dependency "test_tool", "~> 2.0"
          end
        GEMSPEC

        it 'is expected to maintain the type of quote used' do
          expect(subject).to eq(<<~EXPECTED_GEMSPEC)
            Gem::Specification.new do |spec|
              spec.name = "my_project"
              spec.version = "0.1.0"
              spec.add_development_dependency "test_tool", "~> 2.1"
            end
          EXPECTED_GEMSPEC
        end
      end
    end

    context 'when changing a runtime dependency to a development dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_dependency "test_tool", "~> 2.0"
        end
      GEMSPEC

      context 'when force is false' do
        it 'is expected to raise an error' do
          expect { subject }.to raise_error(
            RuntimeError,
            'Trying to add a DEVELOPMENT dependency on "test_tool" ' \
            'which conflicts with the existing RUNTIME dependency. ' \
            'Pass force: true to update dependencies where the ' \
            'dependency type is different.'
          )
        end
      end

      context 'when force is true' do
        let(:force) { true }
        it 'is expected to update the dependency' do
          expect(subject).to eq(<<~EXPECTED_GEMSPEC)
            Gem::Specification.new do |spec|
              spec.name = "my_project"
              spec.version = "0.1.0"
              spec.add_development_dependency "test_tool", "~> 2.1"
            end
          EXPECTED_GEMSPEC
        end
      end
    end

    context 'when changing a development dependency to a runtime dependency' do
      let(:dependency_type) { :runtime }

      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_development_dependency "test_tool", "~> 2.0"
        end
      GEMSPEC

      context 'when force is false' do
        it 'is expected to raise an error' do
          expect { subject }.to raise_error(
            RuntimeError,
            'Trying to add a RUNTIME dependency on "test_tool" ' \
            'which conflicts with the existing DEVELOPMENT dependency. ' \
            'Pass force: true to update dependencies where the ' \
            'dependency type is different.'
          )
        end
      end
    end

    context 'when the gemspec has the given dependency more than once' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_development_dependency "test_tool", "~> 2.0"
          spec.add_development_dependency "test_tool", "~> 2.0"
        end
      GEMSPEC

      it 'is expected to update all instances of the given dependency' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = "my_project"
            spec.version = "0.1.0"
            spec.add_development_dependency "test_tool", "~> 2.1"
            spec.add_development_dependency "test_tool", "~> 2.1"
          end
        EXPECTED_GEMSPEC
      end
    end
  end
end
