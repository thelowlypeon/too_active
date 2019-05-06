require 'spec_helper'

describe TooActive::Analyzer do
  let(:events) { [TooActive::TestEvent.mock] }
  let(:analyzer_class) { described_class }
  let(:analyzer) { analyzer_class.new(events) }

  describe '#initialize' do
    subject { analyzer }

    context 'as a base class' do
      it 'raises because the base analyzer class is abstract' do
        expect { subject }.to raise_error TooActive::Analyzer::InvalidAnalzyerForEvent
      end
    end

    context 'when it is not a base class' do
      let(:analyzer_class) { TooActive::Analyzers::TestAnalyzer }

      context 'with no params' do
        subject { described_class.new }

        it 'has no events' do
          expect(subject).to be_a described_class
        end
      end

      context 'with events param' do
        subject { analyzer }

        it 'has events' do
          expect(subject).to be_a described_class
        end
      end
    end
  end
end
