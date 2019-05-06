module TooActive
  module Analyzers
    class Count < TooActive::Analyzer
      label 'Count'

      def summary_value
        events.count
      end

      def detail_values_for(batch:)
        batch.count
      end

      class << self
        def can_analyze?(_event_class)
          true # all events can be counted
        end
      end
    end
  end
end
