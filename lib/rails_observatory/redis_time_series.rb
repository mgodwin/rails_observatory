
module RailsObservatory

  class RedisTimeSeries
    extend Insertion

    attr_reader :labels, :name, :data

    def self.where(**conditions)
      QueryBuilder.new.where(**conditions)
    end

    def self.from_redis(redis_ts)
      name, labels, data = redis_ts
      new(name:, labels: Hash[*labels.flatten], data: )
    end


    def initialize(name:, labels: {}, data: )
      @name = name
      @labels = labels.deep_symbolize_keys
      @data = data
    end

    def to_ms(duration)
      self.class.to_ms(duration)
    end

    def self.to_ms(duration)
      duration.to_i * 1_000
    end

  end

  class RedisTimeSeries::Range
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
      if @key =~ /_sum/
        @agg_type = :sum
      else
        @agg_type = :avg
      end
      @agg_duration = ((end_time - start_time) / buckets * 1000).to_i
      self
    end

    def reduce
      _ts, value = rollup(buckets: 1).to_a.first
      value
    end

    def start_timestamp
      start_time.to_i * 1000
    end

    def end_timestamp
      end_time.to_i * 1000
    end

    def to_a
      args = ["TS.RANGE", @key]
      if @range.begin.nil?
        args.push "-"
      else
        args.push start_timestamp
      end
      if @range.end.nil?
        args.push "+"
      else
        args.push end_timestamp
      end
      args << "LATEST" if @range.end.nil?
      # When range.end is nil, we also want to align 0 so that our buckets don't change as the time range changes
      if @agg_type && @agg_duration
        if @range.end.present?
          args.push("ALIGN", 'end')
        elsif @range.begin.present?
          args.push("ALIGN", 'start')
        end
        args.push("AGGREGATION", @agg_type.to_s.upcase, @agg_duration, "EMPTY")
      end
      # puts "ARGS ARE #{args.join(" ")}"
      values = $redis.call(*args)
      # Replace "NaN" with nil
      # values is an array of arrays of [[timestamp, value]] pairs
      values.map { |v| v[1] == "NaN" ? [v[0], nil] : v }
    end
  end
end