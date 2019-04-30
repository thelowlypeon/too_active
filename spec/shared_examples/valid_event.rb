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
