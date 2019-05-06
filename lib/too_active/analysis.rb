module TooActive
  class Analysis
    attr_reader :summaries, :details

    def initialize(event_store)
      @event_store = event_store
      @summaries = {}
      @details = {}

      build_analyzers.each do |event_type, analyzers|
        analyzers.each do |analyzer|
          summaries[analyzer.class.get_label] = analyzer.summary
          details[analyzer.class.get_label] = analyzer.details if include_analysis_in_details?(analyzer)
        end
      end
    end

    private

    attr_reader :event_store

    def build_analyzers
      relevant_analyzers = {}
      event_store.events_grouped_by_type.each do |event_klass, events|
        unless relevant_analyzers.key?(event_klass)
          relevant_analyzers[event_klass] = Analyzer.registered_analyzers.keys.select do |analyzer_klass|
            analyzer_klass.can_analyze?(event_klass)
          end.map(&:new)
        end
        events.each do |event|
          relevant_analyzers[event_klass].each { |analyzer| analyzer << event }
        end
      end
      relevant_analyzers
    end

    def include_analysis_in_details?(analyzer)
      analyzer.events_grouped_by_name.count > 1
    end

    def print_cell(value, cell_length)
      "#{value.to_s[0..cell_length].ljustt(cell_length)}"
    end
  end
end
