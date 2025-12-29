module RailsObservatory
  class RedisTimeSeries
    class QueryRangeBuilder < QueryBuilder
      attr_reader :group_label

      def initialize(name, reducer, from: nil, to: nil)
        super()
        @conditions = { name: name, compaction: reducer }
        @samples = nil
        @name = name
        @group_label = 'name'
        @base_reducer = reducer.to_s
        @bin_reducer = reducer.to_s
        @group_reducer = reducer.to_s
        @bin_duration = 10_000 # 10s default
        @range = (from..to)
      end

      def where(**conditions)
        clone = self.clone
        clone.instance_variable_set(:@conditions, @conditions.merge(conditions))
        clone
      end

      def group(label, reducer: nil)
        clone = self.clone
        clone.instance_variable_set(:@group_label, label)
        clone.instance_variable_set(:@group_reducer, reducer.to_s) if reducer
        clone
      end

      def bins(duration, reducer: nil)
        clone = self.clone
        clone.instance_variable_set(:@bin_duration, duration)
        clone.instance_variable_set(:@bin_reducer, reducer) if reducer
        clone
      end

      def to_redis_args
        # agg_duration = build_agg_duration
        mrange_args = ['TS.MRANGE', from_ts, to_ts, 'WITHLABELS']
        mrange_args.push('LATEST')
        mrange_args.push("ALIGN", '0')
        mrange_args.push("AGGREGATION", @bin_reducer.to_s.upcase, @bin_duration, "EMPTY")
        mrange_args.push('FILTER', *redis_filters)
        mrange_args.push("GROUPBY", @group_label, "REDUCE", @group_reducer.upcase)
        mrange_args
      end

      def to_redis_command
        to_redis_args.join(" ")
      end

      def each
        res = redis.call(to_redis_args)
        return if res.nil?

        # Convert timestamps to Time objects for Range
        from_timestamp = from_ts
        to_timestamp = to_ts
        range_from = from_timestamp == "-" ? nil : Time.at(from_timestamp / 1000)
        range_to = to_timestamp == "+" ? Time.now : Time.at(to_timestamp / 1000)

        res.each do |_, labels, data|
          yield RedisTimeSeries::Range.new(
            labels: Hash[*labels.flatten],
            data: data,
            bin_duration: @bin_duration,
            from: range_from,
            to: range_to
          )
        end
      end

      private

      def build_agg_duration
        end_time = @range.end || Time.now
        start_time = @range.begin || 12.months.ago.to_time
        available_datapoints = ((end_time - start_time) / 10.0).to_i
        datapoints = [@samples, available_datapoints].min
        ((end_time - start_time) * 1000 / datapoints).to_i
      end

      def from_ts
        range_begin = @range.begin || ActiveSupport::IsolatedExecutionState[:observatory_slice]&.begin
        if range_begin.nil?
          "-"
        else
          range_begin.to_i * 1000
        end
      end

      def to_ts
        range_end = @range.end || ActiveSupport::IsolatedExecutionState[:observatory_slice]&.end
        if range_end.nil?
          "+"
        else
          range_end.to_i * 1000
        end
      end

    end
  end
end