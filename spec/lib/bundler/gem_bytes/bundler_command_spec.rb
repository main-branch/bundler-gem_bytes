# frozen_string_literal: true

RSpec.describe Bundler::GemBytes::BundlerCommand do
  let(:instance) { described_class.new }

  describe '#exec' do
    subject { instance.exec(command, args) }
    context "when called with 'gem-bytes', 'a', 'b'" do
      let(:command) { 'gem-bytes' }
      let(:args) { %w[a b] }
      it 'should output a hello world message' do
        expected_output = <<~OUTPUT
          Hello from the gem-bytes bundler command
          You called gem-bytes with args: ["a", "b"]
        OUTPUT
        expect { subject }.to output(expected_output).to_stdout
      end
    end
  end
end
