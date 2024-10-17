# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::ScriptExecutor do
  let(:instance) { described_class.new }

  describe '#execute' do
    subject { instance.execute(path_or_uri) }

    context 'when a valid script path is provided' do
      let(:path_or_uri) { 'valid_script.rb' }

      it 'applies the script using Thor actions' do
        expect(instance).to receive(:apply).with('valid_script.rb')
        subject
      end
    end

    context 'when an error occurs during script execution' do
      let(:path_or_uri) { 'invalid_script.rb' }

      it 'raises a runtime error with a descriptive message' do
        allow(instance).to receive(:apply).and_raise(StandardError, 'Error loading script')
        expect { subject }.to raise_error(RuntimeError, /Failed to execute script/)
      end
    end
  end
end
