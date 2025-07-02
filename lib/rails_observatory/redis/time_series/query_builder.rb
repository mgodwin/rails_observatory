require_relative '../connection'
module RailsObservatory
  class TimeSeries
    class QueryBuilder
      include Connection
      include Enumerable

      def initialize
        @conditions = {}
        @samples = nil
        @range_set = false
        @group = nil
        @range = (nil..)
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

      def slice(range)
        clone = self.clone
        clone.instance_variable_set(:@range_set, true)
        clone.instance_variable_set(:@range, range)
        clone
      end

      def downsample(samples, using:)
        clone = self.clone
        clone.instance_variable_set(:@samples, samples)
        clone.instance_variable_set(:@agg_type, using)
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

      def each
        @range = ActiveSupport::IsolatedExecutionState[:observatory_slice] || (nil..) unless @range_set
        agg_duration = build_agg_duration
        mrange_args = ['TS.MRANGE', from_ts, to_ts, 'WITHLABELS']
        mrange_args.push('LATEST')
        if @agg_type
          mrange_args.push("ALIGN", '0') #
          mrange_args.push("AGGREGATION", @agg_type.to_s.upcase, agg_duration, "EMPTY")
        end
        mrange_args.push('FILTER', *ts_filters)

        puts mrange_args.join(" ")
        res = redis.call(mrange_args)
        return if res.nil?

        res.each do |name, labels, data|
          yield TimeSeries.new(
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
        available_datapoints = ((end_time - start_time) / 10.0).to_i
        puts "available_datapoints #{available_datapoints}"
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
        root_labels = @conditions[:name] || @conditions[:parent]
        raise 'Must specify name or parent' if @conditions[:name].blank? && @conditions[:parent].blank?

        @conditions[@group] = "*" if @group
        labels = redis.call('SMEMBERS', "#{root_labels}:labels")
        labels = labels.map { |l| [l.to_sym, nil] }.to_h
        @conditions.reverse_merge!(labels)
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