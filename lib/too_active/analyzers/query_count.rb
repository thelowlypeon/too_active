module TooActive
  module Analyzers
    class QueryCountAnalyzer < TooActive::Analyzer
      #analyzer_for 'sql.active_record'

      def analyze
        {
          'Total SQL Queries': events.count,
          'Total SQL Duration': "#{duration_ms}ms"
        }.merge(
          Hash[
            queries_by_name.map do |name, queries|
              value = {
                value: queries.count
              }
              distinct = distinct_queries(queries)
              value[:details] = "Distinct: #{distinct.map { |count| "#{count}x" }.join(', ')}" if distinct.any?
              [name, value]
            end
          ]
        )
      end

      def total_count
        TooActive::Analysis.new(
          label: 'Query Count',
          value: events.count
        )
      end

      def queries_by_name
        @queries_by_name ||= events.each_with_object({}).each do |event, groups|
          (groups[event.name] ||= []) << event
        end
      end

      def queries_by_sql(batch)
        @queries ||= batch.each_with_object({}).each do |event, groups|
          groups[event.sql] ||= 0
          groups[event.sql] += 1
        end
      end

      def distinct_queries
        queries_by_sql(queries)
          .values
          .sort
          .reverse_each
      end

      def duration_ms(batch = nil)
        (((batch || events).map(&:duration).compact.sum || 0) * 1000).round
      end
    end
  end
end
