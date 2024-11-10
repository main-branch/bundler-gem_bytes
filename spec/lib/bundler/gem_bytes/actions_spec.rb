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

  describe '.gemspec' do
    subject { instance.gemspec(block:) }

    let(:force) { false }

    let(:block) do
      proc { |spec_var, spec|
        # Self is an instance of bundler::GemBytes::Actions::Gemspec
        # It has a context attribute which is our instance
        context.instance_variable_set(:@block_called, true)
        context.instance_variable_set(:@actual_spec_var, spec_var)
        context.instance_variable_set(:@actual_spec, spec)
      }
    end

    let(:block_called) { instance.instance_variable_get(:@block_called) }
    let(:actual_spec_var) { instance.instance_variable_get(:@actual_spec_var) }
    let(:actual_spec) { instance.instance_variable_get(:@actual_spec) }

    before { @block_called = false }

    it 'calls the given block with the spec variable and spec' do
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

          # Call the gemspec method
          instance.gemspec(&block)

          # Check that the block was called
          expect(block_called).to be(true)

          # Check that the correct spec variable was passed to the block
          expect(actual_spec_var).to eq(:spec)

          # Check that the correct spec was passed to the block
          expect(actual_spec.name).to eq('my_gem')
          expect(actual_spec.version.to_s).to eq('0.1.0')
        end
      end
    end
  end
end
