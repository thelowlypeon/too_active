module TooActive
  class EventStore
    attr_reader :events

    def initialize
      @events = []
    end

    def <<(event)
      @events << event unless event.ignore?
    end
  end
end
