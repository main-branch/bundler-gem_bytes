# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Actions::Gemspec do
  let(:instance) { described_class.new(context:) }

  let(:context) { double('ScriptExecutor') }

  describe '#add_dependency' do
    subject { instance.call(gemspec, &block) }

    let(:block) do
      proc { |_receiver_name, _spec|
        add_dependency 'example', '~> 2.0'
      }
    end

    context 'when the gemspec has the given dependency and the new dependency has multiple version constraints' do
      let(:block) do
        proc { |_receiver_name, _spec|
          add_dependency 'example', '~> 2.1', '>= 2.1.4'
        }
      end

      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to update the dependency with the new version constraints' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'example', '~> 2.1', '>= 2.1.4'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency with multiple version constraints' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'example', '~> 1.0', '>= 1.1.2'
        end
      GEMSPEC

      it 'is expected to update the dependency with the new version constraints' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec block is empty' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has no dependencies' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has dependencies by not the given one' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
          spec.add_dependency 'anothergem1', '~> 1.1'
          spec.add_dependency 'anothergem2', '~> 0.9'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_dependency 'anothergem1', '~> 1.1'
            spec.add_dependency 'anothergem2', '~> 0.9'
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency with the same type and version constraint' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_dependency 'example', '~> 2.0'
        end
      GEMSPEC

      it 'is expected to not change the gemspec' do
        expect(subject).to eq(gemspec)
      end
    end

    context 'when the gemspec has the given dependency with a different version constraint' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to update the version constraint' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the version constraint uses double quotes' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to update the version constraing using double quotes' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.add_dependency "example", "~> 2.0"
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has the given dependency more than once' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_dependency "example", "~> 1.0"
          spec.add_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to update all instances of the dependency' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = "my_project"
            spec.version = "0.1.0"
            spec.add_dependency "example", "~> 2.0"
            spec.add_dependency "example", "~> 2.0"
          end
        EXPECTED_GEMSPEC
      end
    end

    context 'when updating a add_runtime_dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_runtime_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to update the version constraint and keep the add_runtime_dependency method' do
        expect(subject).to eq(<<~EXPECTED_GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = "my_project"
            spec.version = "0.1.0"
            spec.add_runtime_dependency "example", "~> 2.0"
          end
        EXPECTED_GEMSPEC
      end
    end

    context 'when updating a add_development_dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = "my_project"
          spec.version = "0.1.0"
          spec.add_development_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to raise an error' do
        expect { subject }.to raise_error(
          RuntimeError,
          'Trying to add a RUNTIME dependency on "example" ' \
          'which conflicts with the existing DEVELOPMENT dependency.'
        )
      end
    end
  end

  describe '#add_runtime_dependency' do
    subject { instance.call(gemspec, &block) }

    let(:block) do
      proc { |_receiver_name, _spec|
        add_runtime_dependency 'example', '~> 2.0'
      }
    end

    context 'when the gemspec has no dependencies' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_runtime_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has an existing add_dependency for the gem' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to update the version constraint and leave the add_dependency method' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.add_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when updating a add_development_dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_development_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to raise an error' do
        expect { subject }.to raise_error(
          RuntimeError,
          'Trying to add a RUNTIME dependency on "example" ' \
          'which conflicts with the existing DEVELOPMENT dependency.'
        )
      end
    end
  end

  describe '#add_development_dependency' do
    subject { instance.call(gemspec, &block) }

    let(:block) do
      proc { |_receiver_name, _spec|
        add_development_dependency 'example', '~> 2.0'
      }
    end

    context 'when the gemspec has no dependencies' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.name = 'my_project'
        end
      GEMSPEC

      it 'is expected to add the dependency' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name = 'my_project'
            spec.add_development_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when the gemspec has an existing dependency for the gem' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_development_dependency 'example', '~> 1.0'
        end
      GEMSPEC

      it 'is expected to update the version constraint and leave the add_dependency method' do
        expect(subject).to eq(<<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.add_development_dependency 'example', '~> 2.0'
          end
        GEMSPEC
      end
    end

    context 'when updating a add_dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to raise an error' do
        expect { subject }.to raise_error(
          RuntimeError,
          'Trying to add a DEVELOPMENT dependency on "example" ' \
          'which conflicts with the existing RUNTIME dependency.'
        )
      end
    end

    context 'when updating a add_runtime_dependency' do
      let(:gemspec) { <<~GEMSPEC }
        Gem::Specification.new do |spec|
          spec.add_runtime_dependency "example", "~> 1.0"
        end
      GEMSPEC

      it 'is expected to raise an error' do
        expect { subject }.to raise_error(
          RuntimeError,
          'Trying to add a DEVELOPMENT dependency on "example" ' \
          'which conflicts with the existing RUNTIME dependency.'
        )
      end
    end
  end
end
