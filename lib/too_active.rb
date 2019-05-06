require 'too_active/event'
Dir[File.join(__dir__, 'too_active/events/*.rb')].each { |f| require f }
require 'too_active/analyzer'
Dir[File.join(__dir__, 'too_active/analyzers/*.rb')].each { |f| require f }
require 'too_active/subscription_manager'
require 'too_active/profiler'
require 'too_active/analysis'
require 'too_active/formatter'

module TooActive
  class << self
    # Profile a block with available analyzers.
    #
    # options:
    #   - events:  array of event names
    #              example: ['sql.active_record']
    #              default: all events for which an Event class is defined
    #   - analyze: hash of analyze options.
    #              if false, this method will return an event store.
    #              all other values will be passed to TooActive#analyze
    #              default: empty hash, which will in turn use defaul #analyze options
    #
    # returns an event store if { analyze: false }, otherwise returns the analysis
    def profile(opts = {}, &block)
      event_names = opts.delete(:events) || default_event_names
      analyze_opts = extract_analyze_opts(opts)

      event_store = Profiler.new(build_event_types_hash(event_names), &block).profile!

      analyze_opts.nil? ? event_store : analyze(event_store, analyze_opts)
    end

    # Analyze the events triggered while executing your block, as contained in the event store
    #
    # options:
    #   - include_details: whether to include more details per event type, per analyzer
    #                      default: true
    #   - stdout:          whether to print the output. if false, this will return a string
    #                      default: true
    def analyze(event_store, opts = {})
      include_details = opts.delete(:include_details) != false
      to_stdout = opts.delete(:stdout) != false

      analysis = Analysis.new(event_store) if event_store.events.any?
      formatter = Formatter.new(analysis, include_details: include_details)
      to_stdout ? formatter.print! : formatter.print
    end

    private

    def extract_analyze_opts(opts)
      analyze_opts = opts.delete(:analyze)
      case analyze_opts
      when false
        nil
      when Hash
        analyze_opts
      else
        {}
      end
    end

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
