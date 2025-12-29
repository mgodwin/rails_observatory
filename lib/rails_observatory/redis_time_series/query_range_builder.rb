module RailsObservatory
  class RedisTimeSeries
    class QueryBuilder
      include RedisConnection
      include Enumerable

      def initialize(name, reducer)
        @conditions = { name: name, compaction: reducer }
        @samples = nil
        @range_set = false
        @name = name
        @group = 'name'
        @base_reducer = reducer.to_s
        @bin_reducer = reducer.to_s
        @group_reducer = reducer.to_s
        @bin_duration = 10_000 # 10s default
        @range = (nil..)
      end

      def where(**conditions)
        clone = self.clone
        clone.instance_variable_set(:@conditions, @conditions.merge(conditions))
        clone
      end

      def group(label, reducer: nil)
        clone = self.clone
        clone.instance_variable_set(:@group, label)
        clone.instance_variable_set(:@group_reducer, reducer.to_s) if reducer
        clone
      end

      def slice(range)
        clone = self.clone
        clone.instance_variable_set(:@range_set, true)
        clone.instance_variable_set(:@range, range)
        clone
      end

      def bins(duration, reducer: nil)
        clone = self.clone
        clone.instance_variable_set(:@bin_duration, duration)
        clone.instance_variable_set(:@bin_reducer, reducer) if reducer
        clone
      end

      def sum
        @agg_type = :sum
        @samples = 1
        if @group
          to_a.index_by { _1.labels[@group] }.transform_values { _1.value }
        else
          to_a.first.value
        end
      end

      def avg
        @agg_type = :avg
        @samples = 1
        if @group
          to_a.index_by { _1.labels[@group] }
        else
          raise "Cannot avg without grouping"
        end
      end

      def last
        if @group
          @agg_type = :last
          @samples = 1
          to_a.index_by { _1.labels[@group] }
        else
          raise "Cannot last without grouping"
        end
      end

      def to_redis_args
        @range = ActiveSupport::IsolatedExecutionState[:observatory_slice] || (nil..) unless @range_set
        # agg_duration = build_agg_duration
        mrange_args = ['TS.MRANGE', from_ts, to_ts, 'WITHLABELS']
        mrange_args.push('LATEST')
        mrange_args.push("ALIGN", '0')
        mrange_args.push("AGGREGATION", @bin_reducer.to_s.upcase, @bin_duration, "EMPTY")
        mrange_args.push('FILTER', *ts_filters)
        mrange_args.push("GROUPBY", @group, "REDUCE", @group_reducer.upcase)
        mrange_args
      end

      def to_redis_command
        to_redis_args.join(" ")
      end

      def each
        res = redis.call(to_redis_args)
        return if res.nil?

        res.each do |_, labels, data|
          yield RedisTimeSeries::Range.new(labels: Hash[*labels.flatten], data:)
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
end