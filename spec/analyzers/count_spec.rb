require 'spec_helper'

describe TooActive::Analyzers::Count do
  let(:events_count) { 3 }
  let(:event_name) { 'Dummy' }
  let(:events) { events_count.times.map { |i| TooActive::TestEvent.mock(name: event_name, id: "id:#{i}")} }

  let(:analyzer) { described_class.new(events) }

  describe '#summary' do
    subject { analyzer.summary }

    it 'counts the events' do
      expect(subject).to have_raw_value events_count
    end
  end

  describe '#details' do
    subject { analyzer.details }

    it 'groups the events' do
      expect(subject).to eq_hash_with_raw_values({
        event_name => {
          'id:0' => 1,
          'id:1' => 1,
          'id:2' => 1
        }
      })
    end

    context 'when there are events with different names' do
      let(:events_a) { [TooActive::TestEvent.mock(name: 'a', id: "id:1")] }
      let(:events_b) { [TooActive::TestEvent.mock(name: 'b', id: "id:1")] }
      let(:events) { events_a + events_b }

      it 'groups the events' do
        expect(subject).to eq_hash_with_raw_values({
          'a' => { 'id:1' => 1 },
          'b' => { 'id:1' => 1 }
        });
      end

      context 'when one name has more events than the other' do
        let(:events_b) { 2.times.map { |i| TooActive::TestEvent.mock(name: 'b', id: "id:#{i}") } }

        it 'orders them by count desc' do
          expect(subject).to eq_hash_with_raw_values({
            'b' => {
              'id:0' => 1,
              'id:1' => 1,
            },
            'a' => { 'id:1' => 1 }
          })
        end
      end
    end
  end
end
