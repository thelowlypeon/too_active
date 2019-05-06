module TooActive
  class Event
    attr_reader :id, :start_time, :end_time, :name

    class InvalidEventType < StandardError; end
    class InvalidEventData < StandardError; end

    def self.from_args(args)
      (name, start_time, end_time, id) = args
      new(name: name, start_time: start_time, end_time: end_time, id: id)
    end

    def initialize(name:, start_time:, end_time:, id:)
      @id = id
      @start_time = start_time
      @end_time = end_time
      @name = name
      validate!
    end

    def ignore?
      false
    end

    def duration
      @duration ||= end_time - start_time
    end

    # by default, all events are conosidered distinct.
    # override this to consider events duplicates, such as multiple
    # SQL events with the same SQL query being executed
    def distinct_value
      id
    end

    class << self
      attr_reader :for_event_type

      def event_class_for(event_name)
        @for_event_type = event_name
      end
    end

    private

    def required_fields_present?
      id && start_time && end_time && name
    end

    def validate!
      raise InvalidEventData, "Missing data" unless required_fields_present?
    end
  end
end
