require 'too_active/event'
Dir[File.join(__dir__, 'too_active/events/*.rb')].each { |f| require f }
require 'too_active/subscription_manager'
require 'too_active/profiler'

module TooActive
  class << self
    def profile(event_names = default_event_names, &block)
      Profiler.new(build_event_types_hash(event_names), &block).profile!
    end

    private

    def subscription_manager
      @subscription_manager ||= SubscriptionManager.new
    end

    def default_event_names
      subscription_manager.event_types.keys
    end

    def build_event_types_hash(event_names)
      event_types = event_names.map do |event_name|
        event_klass = subscription_manager.event_types[event_name]
        raise Event::InvalidEventType, "Invalid event type '#{event_name}'" unless event_klass
        [event_name, event_klass]
      end
      event_types.to_h
    end
  end
end
