module TooActive
  class Formatter
    ROW_DIVIDER = '-----------------------------------------'.freeze
    CELL_LENGTH = 15.freeze

    def initialize(analysis, include_details: true)
      @analysis = analysis
      @include_details = include_details
    end

    def print
      output = [
        ROW_DIVIDER,
        summary,
        ROW_DIVIDER
      ]
      output << details if include_details
      output.compact.join("\n")
    end

    def print!
      puts print
    end

    private

    attr_reader :analysis, :include_details

    def summary
      return 'NO EVENTS'.rjust(CELL_LENGTH / 2) unless analysis
      @summary ||= analysis.summaries.map { |label, value| summary_row(label, value) }.join("\n")
    end

    def details
      return nil unless analysis
      @details ||= analysis.details.map do |label, values|
        detail_rows(label, values).join("\n")
      end.join("\n")
    end

    def summary_row(label, value)
      "#{label.ljust(CELL_LENGTH)}: #{value}"
    end

    def detail_rows(label, values)
      [label] + values.map { |detail_label, value| " * #{summary_row(detail_label, value)}" }
    end
  end
end
