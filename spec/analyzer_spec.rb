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

  describe '#distinct_values_per_group' do
    let(:analyzer_class) { TooActive::Analyzers::TestAnalyzer }
    subject { analyzer.distinct_values_per_group }

    context 'when there are multiple event types but all with the same distinct value' do
      let(:events) { [TooActive::TestEvent.mock(name: 'a', id: 'a1'), TooActive::TestEvent.mock(name: 'b', id: 'b1')] }

      it 'returns the correct set of groups' do
        expect(subject).to eq({
          'a' => { 'a1' => 1 },
          'b' => { 'b1' => 1 },
        })
      end
    end

    context 'when there are multiple distinct values within the same event group' do
      let(:events) {
        [
          TooActive::TestEvent.mock(name: 'a', id: 'a1'),
          TooActive::TestEvent.mock(name: 'a', id: 'a1'),
          TooActive::TestEvent.mock(name: 'a', id: 'a2'),
          TooActive::TestEvent.mock(name: 'b', id: 'b1')
        ]
      }

      it 'returns the correct set of groups' do
        expect(subject).to eq({
          'a' => { 'a1' => 2, 'a2' => 1 },
          'b' => { 'b1' => 1 },
        })
      end
    end
  end
end
