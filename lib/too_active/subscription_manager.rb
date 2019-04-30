module TooActive
  class SubscriptionManager
    def event_types
      @event_types ||= detect_event_types
    end

    private

    def detect_event_types
      ObjectSpace.each_object(Class)
        .select { |klass| klass < Event }
        .map { |klass| [klass.for_event_type, klass] }
        .to_h
    end
  end
end
