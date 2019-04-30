require 'active_support/notifications'
require 'too_active/event_store'

module TooActive
  class Profiler
    attr_reader :event_types, :block, :event_store

    class InvalidRepeatProfile < StandardError; end

    def initialize(event_types, &block)
      @event_types = event_types
      @block = block
      @subscriptions = {}
      @event_store = EventStore.new
      @profiled = false
    end

    def profile!
      raise InvalidRepeatProfile, 'Profiling intended to happen only once' if profiled?
      @profiled = true
      subscribe(event_store)
      @block.call
      event_store
    ensure
      unsubscribe
    end

    def profiled?
      @profiled
    end

    private

    attr_reader :subscriptions

    def subscribe(event_store)
      event_types.each do |event_name, event_klass|
        subscriptions[event_name] = ActiveSupport::Notifications.subscribe(event_name) do |*args|
          event_store << event_klass.from_args(args)
        end
      end
    end

    def unsubscribe
      subscriptions.each do |event_name, subscription|
        ActiveSupport::Notifications.unsubscribe(subscription)
        subscriptions.delete(event_name)
      end
    end
  end
end
