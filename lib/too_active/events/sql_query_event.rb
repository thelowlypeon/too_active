module TooActive
  module Events
    class SqlQuery < TooActive::Event
      attr_reader :sql

      UNRECOGNIZED_QUERY_TYPE = 'unrecognized'.freeze

      event_class_for 'sql.active_record'

      def self.from_args(args)
        (_event_name, start_time, end_time, id, data) = args
        if data && data.is_a?(Hash)
          name = data[:name]
          sql = data[:sql]
        end
        new(name: name, start_time: start_time, end_time: end_time, id: id, sql: sql)
      end

      def initialize(name:, start_time:, end_time:, id:, sql:)
        @sql = sql
        super(id: id, start_time: start_time, end_time: end_time, name: name || name_from_sql(sql))
      end

      def ignore?
        name == 'SCHEMA' || super
      end

      def distinct_value
        sql
      end

      private

      def required_fields
        [:sql] + super
      end

      def name_from_sql(sql)
        match_data = match_select(sql) || match_other_sql(sql)
        if match_data && match_data[:table]
          "#{match_data[:table]} #{match_data[:verb]}"
        else
          UNRECOGNIZED_QUERY_TYPE
        end
      end

      def match_select(sql)
        /^(?<verb>SELECT) .* FROM [\\'"]?(?<table>[\w]+)[\\'"]?/.match(sql) if sql
      end

      def match_other_sql(sql)
        /^(?<verb>\w+)\s+(FROM|INTO)?[\\'"\s]+(?<table>\w+)/.match(sql) if sql
      end
    end
  end
end
