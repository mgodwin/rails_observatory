module RailsObservatory
  class Redis::TimeSeries::QueryBuilder
    include Enumerable

    def initialize(series_class)
      @series_class = series_class
      @conditions = {}
      @samples = nil
      @range = (nil..)
    end

    def where(**conditions)
      if conditions[:name].present?
        conditions => { name:, **rest }
        prefixed_name = begin
                          if name.is_a? Array
                            name.map { |n| "#{@series_class::PREFIX}.#{n}" }
                          else
                            "#{@series_class::PREFIX}.#{name}"
                          end
                        end
        @conditions.merge! name: prefixed_name, **rest
      else
        @conditions.merge! conditions
      end
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
      @samples = samples
      @agg_type = using
      self.clone
    end

    def each
      agg_duration = build_agg_duration
      mrange_args = ['TS.MRANGE', from_ts, to_ts, 'WITHLABELS']
      mrange_args.push('LATEST') if @range.end.nil?
      if @agg_type && @samples
        if @range.end.present?
          mrange_args.push("ALIGN", 'end')
        elsif @range.begin.present?
          mrange_args.push("ALIGN", 'start')
        end
        mrange_args.push("AGGREGATION", @agg_type.to_s.upcase, agg_duration, "EMPTY")
      end
      mrange_args.push('FILTER', *ts_filters)

      puts mrange_args.join(" ")
      res = $redis.call(mrange_args)
      return if res.nil?

      res.each do |name, labels, data|
        yield @series_class.new(
          name:,
          labels: Hash[*labels.flatten],
          data:,
          time_range: @range,
          agg_duration: agg_duration
        )
      end
    end

    private

    def build_agg_duration
      end_time = @range.end || Time.now
      start_time = @range.begin || 12.months.ago.to_time
      ((end_time - start_time) * 1000 / @samples).to_i
    end

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
        elsif v.is_a? Array
          "#{k}=(#{v.join(',')})"
        else
          "#{k}=#{v}"
        end
      end.to_a
    end

  end
end