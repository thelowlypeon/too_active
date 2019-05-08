require 'too_active'

unless defined?(TooActive::TestEvent)
  module TooActive
    class TestEvent < Event
      event_class_for 'too_active.test'

      def self.from_args(args = nil)
        mock
      end

      def self.mock(name: 'Dummy', start_time: Time.at(0), end_time: Time.at(1), id: Time.now.to_i, distinct_value: nil)
        @distinct_value = distinct_value
        new(name: name, start_time: start_time, end_time: end_time, id: id)
      end

      def distinct_value
        @distinct_value || super
      end
    end
  end
end

unless defined?(TooActive::Analyzers::TestAnalyzer)
  module TooActive
    module Analyzers
      class TestAnalyzer < TooActive::Analyzer
        label 'Test Analyzer'

        private

        def summary_value
          'summary value'
        end

        def detail_values_for(batch:)
          'detail'
        end

        def self.can_analyze?(event_class)
          event_class.for_event_type == 'too_active.test'
        end
      end
    end
  end
end

Dir[File.join(__dir__, 'shared_examples/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
