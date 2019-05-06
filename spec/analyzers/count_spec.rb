require 'spec_helper'

describe TooActive::Analyzers::Count do
  let(:events_count) { 10 }
  let(:event_name) { 'Dummy' }
  let(:events) { events_count.times.map { |i| TooActive::TestEvent.mock(name: event_name, id: "test_#{i}")} }

  let(:analyzer) { described_class.new(events) }

  describe '#summary' do
    subject { analyzer.summary }

    it 'counts the events' do
      expect(subject).to eq events_count
    end
  end

  describe '#details' do
    subject { analyzer.details }

    it 'groups the events' do
      expect(subject).to eq({ event_name => events_count })
    end

    context 'when there are events with different names' do
      let(:events_a) { [TooActive::TestEvent.mock(name: 'a', id: "test_a_1")] }
      let(:events_b) { [TooActive::TestEvent.mock(name: 'b', id: "test_b_1")] }
      let(:events) { events_a + events_b }

      it 'groups the events' do
        expect(subject).to eq({ 'a' => 1, 'b' => 1 });
      end

      context 'when one name has more events than the other' do
        let(:events_b) { 2.times.map { |i| TooActive::TestEvent.mock(name: 'b', id: "test_b_#{i}") } }

        it 'orders them by count desc' do
          expect(subject).to eq({ 'b' => 2, 'a' => 1 });
        end
      end

    end
  end
end
