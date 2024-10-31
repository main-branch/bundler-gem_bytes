# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Gemspec::DeleteDependency do
  let(:instance) { described_class.new(gem_name) }

  # let(:dependency_type) { :development }
  let(:gem_name) { 'test_tool' }
  # let(:version_constraint) { '~> 2.1' }
  # let(:force) { false }

  describe '#initialize' do
    subject { instance }

    context 'with valid arguments' do
      let(:expected_attributes) do
        # :nocov: JRuby give false positive for this line being uncovered by tests
        {
          gem_name: 'test_tool',
          found_dependencies: []
        }
        # :nocov:
      end

      it { is_expected.to have_attributes(expected_attributes) }
    end
  end

  describe '#call' do
    subject { instance.call(gemspec) }

    context 'when the gemspec is not valid Ruby code' do
      let(:gemspec) { <<~GEMSPEC }
        This is not valid Ruby code. Please fix this file to continue.
      GEMSPEC

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError, /Invalid syntax in \(string\)/)
      end
    end

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

      it 'is expected to return the gemspec unchanged' do
        expect(subject).to eq(gemspec)
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

      it 'is expected to return the gemspec unchanged' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.version = '0.1.0'
            spec.add_dependency 'another_gem', '~> 1.3'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has a dependency on the given gem' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.version = '0.1.0'
          spec.add_development_dependency 'test_tool', '~> 2.1'
        end
      GEMSPEC

      it 'is expected to remove the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.version = '0.1.0'
          end
        GEMSPEC
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
          end
        EXPECTED_GEMSPEC
      end
    end
  end
end
