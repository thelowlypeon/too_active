require 'spec_helper'

describe TooActive::Analysis do
  let(:events) { [TooActive::TestEvent.mock] }
  let(:event_store) { TooActive::EventStore.new(events: events) }
  let(:analysis) { described_class.new(event_store) }

  describe '#summaries' do
    subject { analysis.summaries }

    it 'includes a summary for all available analyzers' do
      expect(subject).to have_key(TooActive::Analyzers::Count.get_label)
      expect(subject).to have_key(TooActive::Analyzers::Duration.get_label)
      expect(subject).to have_key(TooActive::Analyzers::TestAnalyzer.get_label)
    end
  end

  describe '#details' do
    subject { analysis.details }

    context 'when there is only one kind of distinct event' do
      it 'does not include details when there are only events of a single type' do
        expect(subject).to be_empty
      end
    end

    context 'when there is more than one distinct type of event' do
      let(:events) { [TooActive::TestEvent.mock, TooActive::TestEvent.mock(name: 'Distinct')] }

      it 'includes details for all analyzers' do
        expect(subject).to have_key(TooActive::Analyzers::Count.get_label)
        expect(subject).to have_key(TooActive::Analyzers::Duration.get_label)
        expect(subject).to have_key(TooActive::Analyzers::TestAnalyzer.get_label)
      end

      it 'contains a detail row for each distinct event type' do
        expected_keys = ['Distinct', 'Dummy']
        expect(subject[TooActive::Analyzers::Count.get_label].keys).to match_array expected_keys
        expect(subject[TooActive::Analyzers::Duration.get_label].keys).to match_array expected_keys
        expect(subject[TooActive::Analyzers::TestAnalyzer.get_label].keys).to match_array expected_keys
      end
    end
  end

end
