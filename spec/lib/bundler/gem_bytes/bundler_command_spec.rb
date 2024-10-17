# :nocov:
# Exclude first line in this file from coverage to work around a bug in JRuby
# coverage reporting which marked this line a not covered
# :nocov:

# frozen_string_literal: true

require 'tempfile'

RSpec.describe Bundler::GemBytes::BundlerCommand do
  let(:instance) { described_class.new }
  let(:executor) { instance_double(Bundler::GemBytes::ScriptExecutor) }

  context 'when the executor is mnocked' do
    before do
      allow(Bundler::GemBytes::ScriptExecutor).to receive(:new).and_return(executor)
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

        it 'executes the script using ScriptExecutor' do
          allow(executor).to receive(:execute).with('valid_script.rb')
          expect { subject }.not_to raise_error
        end
      end

      context 'when an error occurs applying the script' do
        let(:args) { ['invalid_script.rb'] }

        it 'outputs an error message to stderr and exits' do
          allow(executor).to receive(:execute).and_raise(RuntimeError, 'Error applying script')
          expect { subject }.to(
            output(/Error applying script/).to_stderr
            .and(raise_error(SystemExit))
          )
        end
      end
    end
  end

  context 'when executor is NOT mocked' do
    it 'executes a real script given by a relative path' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          relative_path = 'test_script.rb'
          File.write(relative_path, <<~SCRIPT)
            puts 'Hello from the script!'
          SCRIPT
          expect { instance.exec('gem-bytes', [relative_path]) }.to output(/Hello from the script!\n/).to_stdout
        end
      end
    end

    it 'executes a real script given by an absolute path' do
      Dir.mktmpdir do |dir|
        absolute_path = File.join(dir, 'test_script.rb')
        File.write(absolute_path, <<~SCRIPT)
          puts 'Hello from the script!'
        SCRIPT
        expect { instance.exec('gem-bytes', [absolute_path]) }.not_to raise_error
        # expect { instance.exec('gem-bytes', [absolute_path]) }.to output(/Hello from the script!\n/).to_stdout
      end
    end

    it 'executes a script with an error in it, outputs the error message, and exits' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          relative_path = 'test_script.rb'
          File.write(relative_path, <<~SCRIPT)
            raise 'Error from the script!'
          SCRIPT
          expect { instance.exec('gem-bytes', [relative_path]) }.to(
            raise_error(SystemExit).and(
              output(/Error from the script!/).to_stderr.and(
                output(/test_script.rb/).to_stdout
              )
            )
          )
        end
      end
    end
  end
end
