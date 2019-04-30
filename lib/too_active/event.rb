module TooActive
  class Event
    attr_reader :id, :start_time, :end_time, :name

    class InvalidEventType < StandardError; end
    class InvalidEventData < StandardError; end

    def self.from_args(*args)
      new(name: args[0], id: args[1], start_time: args[2], end_time: args[3])
    end

    def initialize(id:, start_time:, end_time:, name:)
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
