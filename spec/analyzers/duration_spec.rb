require 'spec_helper'

describe TooActive::Analyzers::Duration do
  let(:events_count) { 10 }
  let(:event_name) { 'Dummy' }
  let(:event_duration) { 1 }
  let(:event_end_time) { Time.at(event_duration) }
  let(:event_start_time) { Time.at(0) }
  let(:events) { events_count.times.map { |i| TooActive::TestEvent.mock(name: event_name, start_time: event_start_time, end_time: event_end_time, id: "test_#{i}")} }

  let(:analyzer) { described_class.new(events) }

  describe '#summary' do
    subject { analyzer.summary }

    it 'counts the events' do
      expect(subject).to eq event_duration * events_count
    end
  end

  describe '#details' do
    subject { analyzer.details }

    it 'groups the events' do
      expect(subject).to eq({ event_name => event_duration * events_count })
    end

    context 'when there are events with different names' do
      let(:events_a) { [TooActive::TestEvent.mock(name: 'a', start_time: event_start_time, end_time: event_end_time, id: "test_a_1")] }
      let(:events_b) { [TooActive::TestEvent.mock(name: 'b', start_time: event_start_time, end_time: event_end_time, id: "test_b_1")] }
      let(:events) { events_a + events_b }

      it 'groups the events' do
        expect(subject).to eq({ 'a' => 1, 'b' => 1 });
      end

      context 'when one event takes longer than another' do
        let(:events_b) { [TooActive::TestEvent.mock(name: 'b', start_time: event_start_time, end_time: event_end_time + 1, id: "test_b_1")] }

        it 'orders them by count desc' do
          expect(subject).to eq({ 'b' => 2, 'a' => 1 });
        end
      end

    end
  end
end

