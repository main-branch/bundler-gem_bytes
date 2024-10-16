# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::BundlerCommand do
  let(:instance) { described_class.new }
  let(:loader) { instance_double(Bundler::GemBytes::ScriptLoader) }

  before do
    allow(Bundler::GemBytes::ScriptLoader).to receive(:new).and_return(loader)
  end

  describe '#exec' do
    subject { instance.exec(command, args) }
    let(:command) { 'gem-bytes' }

    context 'when no arguments are passed' do
      let(:args) { [] }

      it 'outputs an error to stderr and exits' do
        expect { subject }.to(
          output(/Error: You must provide exactly one argument/).to_stderr
          .and(raise_error(SystemExit))
        )
      end
    end

    context 'when more than one argument is passed' do
      let(:args) { %w[file1 file2] }

      it 'outputs an error to stderr and exits' do
        expect { subject }.to(
          output(/Error: You must provide exactly one argument/).to_stderr
          .and(raise_error(SystemExit))
        )
      end
    end

    context 'when a valid script path is passed' do
      let(:args) { ['valid_script.rb'] }

      it 'outputs the content of the script to stdout' do
        allow(loader).to receive(:load).and_return('script content')
        expect { subject }.to output("script content\n").to_stdout
      end
    end

    context 'when an error occurs loading the script' do
      let(:args) { ['invalid_script.rb'] }

      it 'outputs an error message to stderr and exits' do
        allow(loader).to receive(:load).and_raise(RuntimeError.new('File not found'))
        expect { subject }.to(
          output(/Error loading script: File not found/).to_stderr
          .and(raise_error(SystemExit))
        )
      end
    end
  end
end
