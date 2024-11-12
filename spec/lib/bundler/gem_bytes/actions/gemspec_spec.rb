# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::Actions::Gemspec do
  let(:instance) { described_class.new(context:) }

  let(:context) { double('ScriptExecutor') }

  describe '#initialize' do
    subject { instance }

    context 'with valid arguments' do
      let(:expected_attributes) do
        # :nocov: JRuby give false positive for this line being uncovered by tests
        {
          receiver_name: nil,
          gemspec_block: nil,
          dependencies: []
        }
        # :nocov:
      end

      it { is_expected.to have_attributes(expected_attributes) }
    end
  end

  describe '#call' do
    subject { instance.call(gemspec, &block) }

    let(:block) { nil }

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

    context 'when the gemspec has a gem specification section' do
      context 'and it is an empty block' do
        let(:gemspec) { <<~GEMSPEC }
          Gem::Specification.new do |spec|
          end
        GEMSPEC

        it 'is expected to found the receiver name' do
          subject
          expect(instance.receiver_name).to eq(:spec)
        end

        it 'is expected to have found the gemspec block' do
          subject
          expect(instance.gemspec_block.present?).to eq(true)
        end

        it 'is expected to have found no dependencies' do
          subject
          expect(instance.dependencies).to be_empty
        end
      end

      context 'and it contains a dependency' do
        let(:gemspec) { <<~GEMSPEC }
          Gem::Specification.new do |spec|
            spec.add_dependency 'example', '~> 1.0'
          end
        GEMSPEC

        it 'is expected to have found the dependency' do
          subject
          expect(instance.dependencies).to have_attributes(size: 1)
          expected_node = [:send, %i[lvar spec], :add_dependency, [:str, 'example'], [:str, '~> 1.0']]
          expect(instance.dependencies[0].node.to_sexp_array).to eq(expected_node)
          expected_declaration = [:add_dependency, 'example', '~> 1.0']
          expect(instance.dependencies[0].dependency.to_a).to eq(expected_declaration)
        end
      end

      context 'and it contains two dependencies' do
        let(:gemspec) { <<~GEMSPEC }
          Gem::Specification.new do |spec|
            spec.add_dependency 'example1', '~> 1.0'
            spec.add_runtime_dependency 'example2', '~> 2.0'
            spec.add_development_dependency 'example3', '~> 3.0'
          end
        GEMSPEC

        def expected_node(type, name, version)
          [:send, %i[lvar spec], type, [:str, name], [:str, version]]
        end

        def expected_declaration(type, name, version)
          [type, name, version]
        end

        it 'is expected to have found the dependencies' do
          subject
          expect(instance.dependencies).to have_attributes(size: 3)
          expect(instance.dependencies.map { |d| d.node.to_sexp_array }).to eq(
            [
              expected_node(:add_dependency, 'example1', '~> 1.0'),
              expected_node(:add_runtime_dependency, 'example2', '~> 2.0'),
              expected_node(:add_development_dependency, 'example3', '~> 3.0')
            ]
          )
          expect(instance.dependencies.map { |d| d.dependency.to_a }).to eq(
            [
              expected_declaration(:add_dependency, 'example1', '~> 1.0'),
              expected_declaration(:add_runtime_dependency, 'example2', '~> 2.0'),
              expected_declaration(:add_development_dependency, 'example3', '~> 3.0')
            ]
          )
        end
      end

      context 'when called with a block' do
        let(:gemspec) { <<~GEMSPEC }
          Gem::Specification.new do |spec|
            spec.name = 'example'
          end
        GEMSPEC

        let(:block) do
          proc { |receiver_name, spec|
            @test_receiver_name = receiver_name
            @test_spec = spec
          }
        end

        it 'is expected to call the block with the receiver_name and Gem::Specification object' do
          subject
          receiver_name = instance.instance_variable_get('@test_receiver_name')
          spec = instance.instance_variable_get('@test_spec')
          expect(receiver_name).to eq(:spec)
          expect(spec).to be_a(Gem::Specification)
          expect(spec.name).to eq('example')
        end
      end
    end
  end

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
