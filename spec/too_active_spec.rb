require 'spec_helper'

describe TooActive do
  describe '#profile' do
    let(:mock_event) { ActiveSupport::Notifications.instrument('too_active.test') }
    let(:opts) { { analyze: false } }

    let(:block) { ->{ mock_event } }

    subject { TooActive.profile(opts) { block.call } }

    it 'returns an instance of event store' do
      expect(subject).to be_a TooActive::EventStore
    end

    it 'records one event' do
      expect(subject.events.count).to eq 1
      expect(subject.events.first).to be_a TooActive::TestEvent
    end

    context 'when specific event types are defined' do
      let(:event_types) { ['too_active.test'] }
      subject { TooActive.profile(events: event_types, analyze: false) { block.call } }

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

    context 'when analyzing' do
      let(:opts) { { analyze: true } }
      let(:expected_analyze_options) { {} }
      before { allow(TooActive).to receive(:analyze) }

      after { subject }

      shared_examples 'a correct call to analyze' do
        it 'calls analyze with the newly constructed event_store' do
          expect(TooActive).to receive(:analyze) do |event_store, options|
            expect(event_store).to be_a TooActive::EventStore
            expect(options).to eq(expected_analyze_options)
          end
        end
      end

      context 'when the analyze option value is true' do
        it_behaves_like 'a correct call to analyze'
      end

      context 'when the analyzer options are a hash' do
        let(:opts) { { analyze: { foo: :bar } } }
        let(:expected_analyze_options) { { foo: :bar } }

        it_behaves_like 'a correct call to analyze'
      end
    end
  end

  describe '#analyze' do
    let(:events) do
      [TooActive::TestEvent.mock]
    end
    let(:event_store) { TooActive::EventStore.new(events: events) }
    let(:analysis) { double(TooActive::Analysis) }
    let(:formatter) { double(TooActive::Formatter) }
    let(:stdout) { false }
    before do
      allow(TooActive::Analysis).to receive(:new).with(event_store).and_return(analysis)
      allow(TooActive::Formatter).to receive(:new).with(analysis, anything).and_return(formatter)
    end

    subject { TooActive.analyze(event_store, stdout: stdout) }

    context 'when not printing to stdout' do
      before { allow(formatter).to receive(:print) }

      after { subject }

      it 'creates an analysis' do
        expect(TooActive::Analysis).to receive(:new).with(event_store)
      end

      it 'uses the analysis to create a formatter' do
        expect(TooActive::Formatter).to receive(:new).with(analysis, include_details: true)
      end
    end

    context 'when printing to stdout' do
      let(:stdout) { true }

      it 'prints!' do
        expect(formatter).to receive(:print!)
        subject
      end
    end
  end

  describe 'end to end profile with common arguments, primarily for tdd' do
    let(:events_data) do
      [
        { sql: 'SELECT * FROM a WHERE id = 1', name: 'Resource A Load'},
        { sql: 'SELECT * FROM a WHERE id = 1', name: 'Resource A Load'},
        { sql: 'SELECT * FROM a WHERE id = 2', name: 'Resource A Load'},
        { sql: 'SELECT * FROM b WHERE id = 1', name: 'Resource B Load'},
        { sql: 'SELECT * FROM b WHERE id = 1', name: 'Resource B Load'},
        { sql: 'SELECT * FROM b INNER JOIN a ON a.b_id = b.id WHERE b.id = 1 AND other_condition = 1 AND some_other_condition IN (1,2,3,4)', name: 'Resource B Load'},
      ]
    end
    let(:mock_events) { events_data.map { |data| ActiveSupport::Notifications.instrument('sql.active_record', data) } }

    let(:block) { ->{ mock_events } }

    subject { TooActive.profile(analyze: { stdout: false }) { block.call } }

    it 'prints the desired output' do
      expect(subject).to eq %Q(-----------------------------------------
Count          : 6
Duration (ms)  : 0
-----------------------------------------
Count
 * Resource A Load:
   - 2 (SELECT * FROM a WHERE id = 1)
   - 1 (SELECT * FROM a WHERE id = 2)
 * Resource B Load:
   - 2 (SELECT * FROM b WHERE id = 1)
   - 1 (SELECT * FROM b INNER JOIN a...ther_condition IN (1,2,3,4))
Duration (ms)
 * Resource A Load: 0
 * Resource B Load: 0)
    end
  end
end
