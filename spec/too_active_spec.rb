require 'spec_helper'

describe TooActive do
  describe '#profile' do
    let(:mock_event) { ActiveSupport::Notifications.instrument('too_active.test') }

    let(:block) { ->{ mock_event } }

    subject { TooActive.profile { block.call } }

    it 'returns an instance of event store' do
      expect(subject).to be_a TooActive::EventStore
    end

    it 'records one event' do
      expect(subject.events.count).to eq 1
      expect(subject.events.first).to be_a TooActive::TestEvent
    end

    context 'when specific event types are defined' do
      let(:event_types) { ['too_active.test'] }
      subject { TooActive.profile(event_types) { block.call } }

      it 'listens for that event' do
        expect(subject.events.count).to eq 1
      end

      context 'when listening for other event types' do
        let(:event_types) { ['sql.active_record'] }

        it 'does not listen for that event' do
          expect(subject.events).to be_empty
        end
      end

      context 'when the event type is invalid' do
        let(:event_types) { ['unknown'] }

        it 'raises' do
          expect { subject }.to raise_error(TooActive::Event::InvalidEventType, "Invalid event type 'unknown'")
        end
      end
    end
  end
end
