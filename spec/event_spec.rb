require 'spec_helper'

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
