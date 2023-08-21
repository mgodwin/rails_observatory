
module RailsObservatory

  class TimeSeries
    extend Querying
    extend Insertion

    attr_reader :key

    def [](range)
      TimeSeries::Range.new(key, range)
    end

    def last_timestamp
      info['lastTimestamp'].to_i / 1000
    end

    def info
      info_hash = $redis.call("TS.INFO", key).each_slice(2).to_h
      info_hash["labels"] = info_hash["labels"].to_h if info_hash["labels"].present?
      info_hash
    end

    private

    def initialize(key)
      @key = key
    end

    def to_ms(duration)
      self.class.to_ms(duration)
    end

    def self.to_ms(duration)
      duration.to_i * 1_000
    end

  end

  class TimeSeries::Range
    def initialize(key, range)
      @key = key
      @range = range
    end

    def start_time
      if @range.begin.nil?
        raise "TODO"
      else
        @range.begin
      end
    end

    def end_time
      if @range.end.nil?
        Time.now
      else
        @range.end
      end
    end

    def rollup(buckets:)
      # "LATEST", "AGGREGATION", "SUM", to_ms(5.minutes), "EMPTY")
      if @key =~ /_count\Z/
        @agg_type = :sum
      else
        @agg_type = :avg
      end
      @agg_duration = ((end_time - start_time) / buckets * 1000).to_i
      self
    end

    def start_timestamp
      start_time.to_i * 1000
    end

    def end_timestamp
      end_time.to_i * 1000
    end

    def to_a
      args = ["TS.RANGE", @key, start_timestamp, end_timestamp]
      args << "LATEST" if @range.end.nil?
      # When range.end is nil, we also want to align 0 so that our buckets don't change as the time range changes
      if @agg_type && @agg_duration
        args.push("AGGREGATION", @agg_type.to_s.upcase, @agg_duration, "EMPTY")
      end
      puts "ARGS ARE #{args}"
      values = $redis.call(*args)
      # Replace "NaN" with nil
      # values is an array of arrays of [[timestamp, value]] pairs
      values.map { |v| v[1] == "NaN" ? [v[0], nil] : v }
    end
  end
end