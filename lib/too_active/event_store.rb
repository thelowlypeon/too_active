module TooActive
  class EventStore
    attr_reader :events

    def initialize(events: [])
      @events = events
    end

    def <<(event)
      @events << event unless event.ignore?
    end

    def events_grouped_by_type
      types = {}
      events.each do |event|
        (types[event.class] ||= []) << event
      end
      types
    end
  end
end
