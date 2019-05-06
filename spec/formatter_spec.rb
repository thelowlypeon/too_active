require 'spec_helper'

describe TooActive::Formatter do
  let(:events) { [TooActive::TestEvent.mock] }
  let(:event_store) { TooActive::EventStore.new(events: events) }
  let(:analysis) { TooActive::Analysis.new(event_store) }
  let(:formatter) { described_class.new(analysis) }

  describe 'print' do
    subject { formatter.print }

    it 'returns a string' do
      expect(subject).to be_a String
    end

    it 'includes analyzer labels' do
      expect(subject).to include(TooActive::Analyzers::Count.get_label)
    end
  end
end
