require 'too_active/sql_parsing'
require 'spec_helper'

describe TooActive::SqlParsing::AbstractQuery do
  let(:sql) {}
  let(:query) { described_class.from_sql(sql) }

  shared_examples 'a query with verb' do |expected_verb|
    it 'matches the verb' do
      expect(query.verb).to eq expected_verb
    end
  end

  shared_examples 'a query on tablename' do |expected_tablename|
    it 'matches the tablename' do
      expect(query.tablename).to eq expected_tablename
    end
  end

  shared_examples 'a query with conditions' do |expected_conditions|
    it 'matches the conditions' do
      expect(query.conditions).to eq expected_conditions
    end
  end

  context 'for a select query' do
    context 'with no joins or conditions' do
      let(:sql) { 'SELECT * FROM tablename' }

      it_behaves_like 'a query with verb', :select
      it_behaves_like 'a query on tablename', 'tablename'

      context 'with a count query' do
        let(:sql) { 'SELECT COUNT(*) FROM tablename WHERE condition = 1' }
        subject { query }

        it { is_expected.to be_a TooActive::SqlParsing::CountQuery }
      end
    end

    context 'when conditions' do
      let(:sql) { 'SELECT * FROM tablename WHERE id = 7 AND field IS NOT NULL' }

      it_behaves_like 'a query with verb', :select
      it_behaves_like 'a query on tablename', 'tablename'
      it_behaves_like 'a query with conditions', ['id = 7', 'field IS NOT NULL']
    end

    context 'with joins' do
      let(:sql) { 'SELECT COUNT(*) FROM tablename INNER JOIN innerjointable ON innerjointable.table_id = tablename.id LEFT OUTER JOIN t ON t.id = tablename.id GROUP BY tablename.id' }

      it_behaves_like 'a query on tablename', 'tablename INNER JOIN innerjointable ON innerjointable.table_id = tablename.id LEFT OUTER JOIN t ON t.id = tablename.id'
    end

    context 'with lots of quotes' do
      let(:sql) { 'SELECT * FROM "tablename"' }

      it_behaves_like 'a query with verb', :select
      it_behaves_like 'a query on tablename', 'tablename'
    end
  end

  context 'for an update query' do
    let(:sql) { "UPDATE tablename SET column = 'value' WHERE id = 7" }

    it_behaves_like 'a query with verb', :update
    it_behaves_like 'a query on tablename', 'tablename'
    it_behaves_like 'a query with conditions', ['id = 7']
    it 'matches the updated values' do
      expect(query.updates).to eq ["column = 'value'"]
    end
  end

  context 'for an insert query' do
    let(:sql) { "INSERT INTO tablename (string, decimal, int) VALUES ('value', 1.2, 1)" }

    it_behaves_like 'a query with verb', :insert
    it_behaves_like 'a query on tablename', 'tablename'

    describe '#values' do
      subject { query.values }

      it 'grabs the inserted values part of the query' do
        expect(subject).to eq "(string, decimal, int) VALUES ('value', 1.2, 1)"
      end
    end

    describe '#values_hash' do
      subject { query.values_hash }

      it 'creates a hash of updated values' do
        expect(subject).to eq({ string: 'value', decimal: 1.2, int: 1 })
      end
    end
  end

  context 'for a delete query' do
    let(:sql) { "DELETE FROM tablename WHERE id = 7" }

    it_behaves_like 'a query with verb', :delete
    it_behaves_like 'a query on tablename', 'tablename'
    it_behaves_like 'a query with conditions', ['id = 7']
  end

  context 'for an unrecognized query type' do
    let(:sql) { 'SCHEMA something' }

    it_behaves_like 'a query with verb', :schema
  end
end


