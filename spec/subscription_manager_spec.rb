require 'spec_helper'

describe TooActive::SubscriptionManager do
  let(:subscription_manager) { described_class.new }

  describe '#event_types' do
    subject { subscription_manager.event_types }

    it { is_expected.to be_a Hash }

    it 'defaults to all children of Event' do
      subject.values.each do |event|
        expect(event < TooActive::Event).to be true
      end
    end

    it 'maps the event type to the event' do
      subject.each do |event_name, event_type|
        expect(event_name).to eq event_type.for_event_type
      end
    end

    context 'when a new subclass is defined' do
      let!(:dummy) { Class.new(TooActive::Event) { event_class_for 'dummy' } }

      it 'includes the dummy event' do
        expect(subject['dummy']).to be dummy
      end
    end
  end
end
