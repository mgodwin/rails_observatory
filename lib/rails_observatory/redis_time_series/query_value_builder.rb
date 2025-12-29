module RailsObservatory
  class RedisTimeSeries
    class QueryValueBuilder < QueryBuilder
      def initialize(name, reducer, from: nil, to: nil)
        super()
        @conditions = {name: name, compaction: reducer}
        @name = name
        @group = "name"
        @reducer = reducer.to_s
        @range = (from..to)
      end

      def where(**conditions)
        clone = self.clone
        clone.instance_variable_set(:@conditions, @conditions.merge(conditions))
        clone
      end

      def group(label)
        clone = self.clone
        clone.instance_variable_set(:@group, label)
        clone
      end

      def to_redis_args
        mrange_args = ["TS.MRANGE", from_ts, to_ts, "WITHLABELS"]
        mrange_args.push("LATEST")
        mrange_args.push("AGGREGATION", @reducer.upcase, agg_duration)
        mrange_args.push("FILTER", *redis_filters)
        mrange_args.push("GROUPBY", @group, "REDUCE", @reducer.upcase)
        mrange_args
      end

      def to_redis_command
        to_redis_args.join(" ")
      end

      def each
        res = redis.call(to_redis_args)
        return if res.nil?

        res.each do |_, labels, data|
          value = data.last&.last&.to_f || 0
          yield RedisTimeSeries::Value.new(labels: Hash[*labels.flatten], value: value)
        end
      end

      private

      def agg_duration
        slice = ActiveSupport::IsolatedExecutionState[:observatory_slice]
        end_time = @range.end || slice&.end || Time.now
        start_time = @range.begin || slice&.begin || 12.months.ago.to_time
        ((end_time - start_time) * 1000).to_i
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
