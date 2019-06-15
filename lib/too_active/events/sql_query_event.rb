require 'too_active/sql_parsing'

module TooActive
  module Events
    class SqlQuery < TooActive::Event
      attr_reader :sql, :query, :binds

      UNRECOGNIZED_QUERY_TYPE = 'unrecognized'.freeze

      event_class_for 'sql.active_record'

      def self.from_args(args)
        (_event_name, start_time, end_time, id, data) = args
        if data && data.is_a?(Hash)
          name = data[:name]
        end
        new(name: name, start_time: start_time, end_time: end_time, id: id, data: data)
      end

      def initialize(name:, start_time:, end_time:, id:, data: {})
        extract_data(data)
        super(id: id, start_time: start_time, end_time: end_time, name: name || @query.description)
      end

      def ignore?
        name == 'SCHEMA' || query.is_a?(SqlParsing::UnrecognizedQuery) || super
      end

      def distinct_value
        if query.is_a?(SqlParsing::SelectQuery) && query.limit == 1
          id = binds.find { |bind| bind[0] == 'id' && bind[1].is_a?(Numeric) } if binds
          if id
            return "id:#{id}"
          elsif query.orders
            return "#{query.orders.join(', ')}"
          end
        end
        @query.description
      end

      private

      def extract_data(data)
        @sql = data[:sql]
        @query = SqlParsing::AbstractQuery.from_sql(@sql)
        # data[:binds] is an array of tuples [column info, value]
        @binds = data[:binds].map { |bind| [bind[0].name, bind[1]] }.to_h if data[:binds]
      end

      def required_fields
        [:sql] + super
      end
    end
  end
end
