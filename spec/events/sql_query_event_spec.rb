require 'spec_helper'

describe TooActive::Events::SqlQuery do
  let(:event_name) { 'sql.active_record' }
  let(:id) { Time.now.to_i }
  let(:start_time) { end_time - 1 }
  let(:end_time) { Time.now }
  let(:sql) { 'SELECT * FROM "models";' }
  let(:name) { 'Model load' }
  let(:data) do
    {
      name: name,
      sql: sql,
      other_stuff: 'some value'
    }
  end

  describe '.from_args' do
    let(:args) { [event_name, start_time, end_time, id, data] }
    subject { described_class.from_args(args) }

    context 'when the args are as expected from active support' do
      it 'instantiates the event' do
        expect(subject.sql).to eq 'SELECT * FROM "models";'
      end

      it_behaves_like 'a valid event'
    end

    context 'when some args are missing' do
      context 'when there is no sql query' do
        let(:sql) { nil }

        it 'raises' do
          expect { subject }.to raise_error(TooActive::Event::InvalidEventData, 'Missing data: sql')
        end
      end

      context 'when there is no name' do
        let(:name) { nil }

        it 'extracts a name from the SELECT and FROM clauses of the SQL query' do
          expect(subject.name).to eq 'models SELECT'
        end

        context 'when it is not a select query' do
          let(:sql) { 'UPDATE "table" SET "field" = "value" WHERE id = 5;' }

          it 'uses the verb and table name from the SQL query' do
            expect(subject.name).to eq 'table UPDATE'
          end
        end
      end
    end
  end

  describe '#ignore?' do
    let(:query_event) { described_class.new(id: id, start_time: start_time, end_time: end_time, name: name, sql: sql) }
    subject { query_event.ignore? }

    context 'when the sql is a SCHEMA query' do
      let(:name) { 'SCHEMA' }

      it 'ignores' do
        expect(subject).to be true
      end
    end
  end
end
