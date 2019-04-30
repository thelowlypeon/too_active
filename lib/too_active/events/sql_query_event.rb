module TooActive
  module Events
    class SqlQuery < TooActive::Event
      attr_reader :sql

      UNRECOGNIZED_QUERY_TYPE = 'unrecognized'.freeze

      event_class_for 'sql.active_record'

      def self.from_args(args)
        data = args[4] || {}
        new(id: args[1], start_time: args[2], end_time: args[3], name: data[:name], sql: data[:sql])
      end

      def initialize(id:, start_time:, end_time:, name:, sql:)
        @sql = sql
        super(id: id, start_time: start_time, end_time: end_time, name: name || name_from_sql)
      end

      def ignore?
        name == 'SCHEMA' || super
      end

      private

      def required_fields_present?
        super && sql
      end

      def name_from_sql
        match_data = match_select(sql) || match_other_sql(sql)
        if match_data && match_data[:table]
          "#{match_data[:table]} #{match_data[:verb]}"
        else
          UNRECOGNIZED_QUERY_TYPE
        end
      end

      def match_select(sql)
        /^(?<verb>SELECT) .* FROM [\\'"]?(?<table>[\w]+)[\\'"]?/.match(sql)
      end

      def match_other_sql(sql)
        /^(?<verb>\w+)\s+(FROM|INTO)?[\\'"\s]+(?<table>\w+)/.match(sql)
      end
    end
  end
end
