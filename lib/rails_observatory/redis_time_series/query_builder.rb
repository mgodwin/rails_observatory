module RailsObservatory
  class RedisTimeSeries::QueryBuilder
    include Enumerable

    def initialize
      @conditions = {}
      @range = (nil..)
    end

    def where(**conditions)
      @conditions.merge! conditions
      self.clone
    end

    def slice(range)
      @range = range
      self.clone
    end

    def initialize_copy(orig)
      @conditions = @conditions.clone
      super
    end

    def downsample(samples, using:)
      @agg_type = using
      end_time = @range.end || Time.now
      start_time = @range.begin || 12.months.ago.to_time
      @agg_duration = (end_time - start_time) * 1000 / samples
      self.clone
    end

    def each
      mrange_args = ['TS.MRANGE', from_ts, to_ts, 'WITHLABELS']
      mrange_args.push('LATEST') if @range.end.nil?
      if @agg_type && @agg_duration
        if @range.end.present?
          mrange_args.push("ALIGN", 'end')
        elsif @range.begin.present?
          mrange_args.push("ALIGN", 'start')
        end
        mrange_args.push("AGGREGATION", @agg_type.to_s.upcase, @agg_duration.to_i, "EMPTY")
      end
      mrange_args.push('FILTER', *ts_filters)

      res = $redis.call(mrange_args)
      return if res.nil?
      res.each { yield RedisTimeSeries.from_redis(_1) }
    end

    private

    def from_ts
      if @range.begin.nil?
        "-"
      else
        @range.begin.to_i * 1000
      end
    end

    def to_ts
      if @range.end.nil?
        "+"
      else
        @range.end.to_i * 1000
      end
    end

    def ts_filters
      @conditions.map do |k, v|
        if v == "*"
          "#{k}!="
        else
          "#{k}=#{v}"
        end
      end.to_a
    end

  end
end