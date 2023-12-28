module RailsObservatory

  class RedisTimeSeries
    extend Insertion

    attr_reader :labels, :name, :data

    def self.where(**conditions)
      QueryBuilder.new(self).where(**conditions)
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
      @time_range.end.nil? ? Time.now : @time_range.end
    end

    def filled_data
      if @time_range.end.nil?
        Enumerator
          .produce(to_ms(start_time)) { |t| t + @agg_duration }
          .take_while { |t| t < to_ms(end_time) }
          .map do |t|
          match = data.find { |ts, _| ts == t }
          if match
            timestamp, val = match
            [timestamp, val.to_f]
          else
            [t, 0]
          end
        end
      else
        data.map do |ts, value|
          [ts, value.to_i || 0]
        end
      end
    end

    def empty?
      data.empty?
    end

    def value
      data.dig(0, 1)
    end

    def to_ms(duration)
      self.class.to_ms(duration)
    end

    def self.to_ms(duration)
      duration.to_i * 1_000
    end
  end
end