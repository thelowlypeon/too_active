module TooActive
  # An Analyzer is what is used to look at a group of events and tell you something about them.
  # To define your own analyzers, you must implement the following:
  # 
  # def self.can_analyze?(event)
  #
  # def summary
  #
  # def detail_values_for(batch:)
  #
  # And your class must define its label using `label 'Label'`
  #
  # See Analyzers::Count for an example.
  class Analyzer
    class InvalidAnalzyerForEvent < StandardError; end

    class << self
      attr_reader :get_label

      def registered_analyzers
        @registered_analyzers ||= {}
      end

      def can_analyze?(event_class)
        false
      end

      def label(title)
        @get_label = title
        TooActive::Analyzer.registered_analyzers[self] = title
      end
    end

    def initialize(events = [])
      @events = []
      events.each do |event|
        self << event
      end
    end

    def <<(event)
      unless self.class.can_analyze?(event.class)
        raise InvalidAnalzyerForEvent, "Invalid event #{event} for analyzer #{self}"
      end
      events << event
    end

    def events_grouped_by_name
      @events_grouped_by_name ||= events.each_with_object({}).each do |event, groups|
        (groups[event.name] ||= []) << event
      end
    end

    # eg
    # {
    #   'Company Load': {
    #     'SELECT ... WHERE id = 7' => 1,
    #     'SELECT ... WHERE id = 9' => 30
    #   }
    # }
    def distinct_values_per_group
      @distinct_values_per_group ||= begin
        events_grouped_by_name.each_with_object({}) do |grouped_events, all_groups|
          (name, events) = grouped_events
          all_groups[name] = events.each_with_object({}).each do |event, groups|
            groups[event.distinct_value] ||= 0
            groups[event.distinct_value] += 1
          end
        end
      end
    end

    def summary
      summary_value
    end

    def details
      events_grouped_by_name
        .map { |name, batch| [name, detail_values_for(batch: batch)] }
        .sort { |a, b| sort_events(a[1], b[1]) }
        .to_h
    end

    private

    attr_reader :events

    def summary_value
      raise 'not implemented'
    end

    def detail_values_for(batch:)
      raise 'not implemented'
    end

    def sort_events(a, b)
      b <=> a
    end
  end
end
