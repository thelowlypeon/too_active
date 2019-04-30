require 'spec_helper'

RSpec.shared_examples 'a valid event' do
  it { is_expected.to be_a TooActive::Event }

  it 'has all the required fields of an event' do
    expect(subject.id).to eq id
    expect(subject.start_time).to eq start_time
    expect(subject.end_time).to eq end_time
    expect(subject.name).to eq name
  end

  context 'when an attribute is missing' do
    let(:start_time) { nil }

    it 'raises' do
      expect { subject }.to raise_error(TooActive::Event::InvalidEventData, 'Missing data')
    end
  end
end

describe TooActive::Event do
  let(:name) { 'dummy' }
  let(:id) { Time.now.to_i }
  let(:start_time) { end_time - 1 }
  let(:end_time) { Time.now }
  let(:data) do
    {
      other_stuff: 'some value'
    }
  end
  let(:event) { described_class.new(name: name, id: id, start_time: start_time, end_time: end_time) }

  describe '.from_args' do
    let(:args) { [name, id, start_time, end_time, data] }
    subject { described_class.from_args(*args) }

    it_behaves_like 'a valid event'
  end

  describe '#initialize' do
    subject { event }

    it_behaves_like 'a valid event'
  end

  describe '#duration' do
    subject { event.duration }
    let(:duration) { 1 }
    let(:start_time) { end_time - duration }

    it 'returns the difference in time' do
      expect(subject).to eq duration
    end
  end
end
