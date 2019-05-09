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
        detail_group(label, values).join("\n")
      end.join("\n")
    end

    def summary_row(label, value)
      "#{label.ljust(CELL_LENGTH)}: #{value}"
    end

    # this is a bit weird. the goal is for `ResultSet`s to look like:
    #  * {ResultSetName}:
    #    - {value} ({distinct_value})
    #
    # and `Result`s to loook like:
    #
    #  * {ResultName}: {value}
    def detail_group(label, values)
      [label] + values.map do |detail_label, value|
        header = " * #{detail_label}:"
        if value.is_a?(TooActive::Analyzer::ResultSet)
          [header] + value.raw_value.map do |sublabel, subvalue|
            "   - #{subvalue} (#{smart_truncate_string(sublabel)})"
          end
        else
          ["#{header} #{value}"]
        end
      end
    end

    def smart_truncate_string(string, length: 60)
      return string if string.length <= length
      substring_length = length / 2 - 3
      "#{string[0..substring_length]}...#{string[(string.length - substring_length)..string.length]}"
    end
  end
end
