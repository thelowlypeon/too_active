require 'spec_helper'

describe TooActive::EventStore do

  describe '<<' do
    let(:event) { TooActive::TestEvent.mock }
    let(:event_store) { described_class.new }
    subject { event_store << event }

    it 'adds the event' do
      expect { subject }.to change { event_store.events.count }.by(1)
    end

    context 'when the event is being ignored' do
      before { expect(event).to receive(:ignore?).and_return(true) }

      it 'does not add the event' do
        expect { subject }.to_not change { event_store.events }
      end
    end
  end

end
