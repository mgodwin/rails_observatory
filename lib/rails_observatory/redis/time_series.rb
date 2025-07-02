require_relative 'time_series/insertion'
require_relative 'time_series/query_builder'
require_relative './connection'

module RailsObservatory
  class TimeSeries
    extend Insertion
    include Connection

    attr_reader :labels, :name, :data

    def self.with_slice(time_range)
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = time_range
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = nil
    end

    def self.where(**conditions)
      QueryBuilder.new.where(**conditions)
    end

    def initialize(name:, labels: {}, data:, time_range:, agg_duration:)
      @name = name
      @time_range = time_range
      @agg_duration = agg_duration
      @labels = labels.deep_symbolize_keys
      @data = data
    end

    def start_time
      @time_range.begin.nil? ? Time.utc(2023, 1, 1, 0, 0, 0) : @time_range.begin
    end

    def start_time_ms
      start_time.to_i.in_milliseconds
    end

    def end_time_ms
      end_time.to_i.in_milliseconds
    end

    def end_time
      @time_range.end
    end

    def filled_data
      # Align to epoch
      start_bucket = start_time_ms - (start_time_ms % @agg_duration)
      # puts "Filling data from #{start_time_ms} to #{end_time_ms} with agg_duration #{@agg_duration}"
      # puts "Start bucket: #{start_bucket}"
      Enumerator
        .produce(start_bucket) { |t| t + @agg_duration }
        .take_while { |t| t < end_time_ms }
        .map do |t|
        match = data.find { |ts, _| ts == t }
        if match
          timestamp, val = match
          [timestamp, val.to_f]
        else
          [t, 0]
        end
      end
    end

    def empty?
      data.empty?
    end

    def value
      @value ||= data.reduce(0) { |sum, (_, value)| sum + value.to_i }
    end

    def to_ms(duration)
      self.class.to_ms(duration)
    end

    def self.to_ms(duration)
      duration.to_i * 1_000
    end
  end
end