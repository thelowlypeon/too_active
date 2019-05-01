module TooActive
  class SubscriptionManager
    def event_types
      @event_types ||= detect_event_types
    end

    private

    def detect_event_types
      # note: this is probably not the ideal way to find children of Event.
      # selecting by for_event_type helps this, and is required to avoid rspec's mocks
      ObjectSpace.each_object(Class)
        .select { |klass| klass < Event }
        .select(&:for_event_type)
        .map { |klass| [klass.for_event_type, klass] }
        .to_h
    end
  end
end
