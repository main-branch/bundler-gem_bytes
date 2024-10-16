# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::ScriptLoader do
  let(:file_system) { double('File') }
  let(:uri_opener) { double('URI Opener') }

  describe '#load' do
    context 'when source is an HTTP URI' do
      let(:uri_string) { 'http://example.com/script.rb' }

      it 'loads the script content from the URI' do
        allow(uri_opener).to receive(:call).with(uri_string).and_return(StringIO.new('script content'))

        loader = described_class.new(uri_string, uri_opener:)
        result = loader.load

        expect(uri_opener).to have_received(:call).with(uri_string)
        expect(result).to eq('script content')
      end

      it 'raises an error if the URI request fails' do
        allow(uri_opener).to receive(:call).with(uri_string).and_raise(StandardError.new('404 Not Found'))

        loader = described_class.new(uri_string, uri_opener:)

        expect { loader.load }.to raise_error("Failed to load script from URI: #{uri_string}, error: 404 Not Found")
      end
    end

    context 'when source is a file URI' do
      let(:uri_string) { 'file:///path/to/local_script.rb' }

      it 'loads the script content from a file URI' do
        allow(uri_opener).to receive(:call).with(uri_string).and_return(StringIO.new('file content from URI'))

        loader = described_class.new(uri_string, uri_opener:)
        result = loader.load

        expect(uri_opener).to have_received(:call).with(uri_string)
        expect(result).to eq('file content from URI')
      end
    end

    context 'when source is a filename' do
      let(:filename) { 'local_script.rb' }

      it 'loads the script content from the file' do
        allow(file_system).to receive(:exist?).with(filename).and_return(true)
        allow(file_system).to receive(:read).with(filename).and_return('file content')

        loader = described_class.new(filename, file_system:)
        result = loader.load

        expect(file_system).to have_received(:exist?).with(filename)
        expect(file_system).to have_received(:read).with(filename)
        expect(result).to eq('file content')
      end

      it 'raises an error if the file does not exist' do
        allow(file_system).to receive(:exist?).with(filename).and_return(false)

        loader = described_class.new(filename, file_system:)

        expect { loader.load }.to raise_error("File not found: #{filename}")
      end
    end

    context 'when source is a mailto: URI' do
      let(:uri_string) { 'mailto:someone@example.com' }

      it 'raises an error indicating unsupported URI scheme' do
        allow(uri_opener).to receive(:call).with(uri_string).and_raise(StandardError.new('unsupported URI scheme'))

        loader = described_class.new(uri_string, uri_opener:)

        expect do
          loader.load
        end.to raise_error(/Failed to load script from URI: mailto:someone@example.com, error: unsupported URI scheme/)
      end
    end

    context 'when source is an invalid URI' do
      let(:invalid_input) { '::invalid_uri::' }

      it 'treats the source as a filename due to URI::InvalidURIError' do
        allow(file_system).to receive(:exist?).with(invalid_input).and_return(true)
        allow(file_system).to receive(:read).with(invalid_input).and_return('file content')

        loader = described_class.new(invalid_input, file_system:)
        result = loader.load

        expect(file_system).to have_received(:exist?).with(invalid_input)
        expect(file_system).to have_received(:read).with(invalid_input)
        expect(result).to eq('file content')
      end
    end
  end
end
