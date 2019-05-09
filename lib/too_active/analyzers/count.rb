module TooActive
  module Analyzers
    class Count < TooActive::Analyzer
      label 'Count'

      def summary_value
        events.count
      end

      def detail_values_for(batch:)
        distinct_events = {}
        batch.each do |event|
          distinct_events[event.distinct_value] ||= 0
          distinct_events[event.distinct_value] += 1
        end
        TooActive::Analyzer::ResultSet.new(distinct_events)
      end

      class << self
        def can_analyze?(_event_class)
          true # all events can be counted
        end
      end
    end
  end
end
