module TooActive
  module Analyzers
    class Duration < TooActive::Analyzer
      label 'Duration (ms)'

      def summary_value
        events.map(&:duration).inject(:+)
      end

      def detail_values_for(batch:)
        batch.map(&:duration).inject(:+)
      end

      class << self
        def can_analyze?(_event_class)
          true # all events can be counted
        end
      end
    end
  end
end
