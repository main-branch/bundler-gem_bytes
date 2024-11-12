# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Actions::Gemspec do
  let(:instance) { described_class.new(context:) }

  let(:context) { double('ScriptExecutor') }

  describe '#remove_dependency' do
    subject { instance.call(gemspec, &block) }

    let(:block) do
      proc { |_receiver_name, _spec|
        remove_dependency 'example'
      }
    end

    context 'when the gemspec has the given dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to remove the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency more than once' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'example', '~> 1.0'
          spec.add_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to remove all instances of the dependency' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
          end
        EXPECTED_GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency amounst others' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'alpha', '~> 1.0'
          spec.add_dependency 'example', '~> 1.0'
          spec.add_dependency 'omega', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to only remove the given dependency' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'alpha', '~> 1.0'
            spec.add_dependency 'omega', '~> 1.0'
          end
        EXPECTED_GEMSPEC
      end
    end

    context 'when the gemspec does not have the given dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'another-example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to remove all instances of the dependency' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'another-example', '~> 1.0'
          end
        EXPECTED_GEMSPEC
      end
    end
  end
end
