module RailsObservatory
  class RedisTimeSeries
    extend Insertion
    include RedisConnection

    attr_reader :key

    def self.with_slice(time_range)
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = time_range
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = nil
    end

    def self.query_range(name, reducer, from: nil, to: nil)
      QueryRangeBuilder.new(name, reducer, from:, to:)
    end

    # Parses a query string and returns a configured QueryRangeBuilder
    # Format: "metric_name|compaction->bins@reducer (group_label)"
    # The bins value specifies the target number of data points to return.
    # Examples:
    #   "request.count|sum->60@sum"      - 60 data points
    #   "request.latency|avg->60@avg (namespace)"
    def self.query_range_by_string(spec, from: nil, to: nil)
      /\A(?<metric_name>.+?)\|(?<compaction>[^->]+)->(?<buckets>\d+)@(?<rollup_fn>.+?)(?:\s*\((?<group_by>\w+)\))?\z/ =~ spec

      raise ArgumentError, "Invalid query spec: #{spec}" unless metric_name

      # Fall back to IsolatedExecutionState if not provided
      from ||= ActiveSupport::IsolatedExecutionState[:observatory_slice]&.begin
      to ||= ActiveSupport::IsolatedExecutionState[:observatory_slice]&.end || Time.now

      target_bins = buckets.to_i

      if from && to
        bin_duration_ms = ((to.to_i - from.to_i) * 1000 / target_bins).to_i
        bin_duration_ms = [bin_duration_ms, 1000].max # Minimum 1 second bins
      else
        bin_duration_ms = 60_000 # Fallback: 60 second bins
      end

      conditions = {}
      group_label = group_by || "name"

      if group_by && group_by != "name"
        conditions[group_by.to_sym] = true
      end

      conditions[:compaction] = if compaction == "all"
        true # Match any compaction (exists filter)
      else
        compaction
      end

      query_range(metric_name, rollup_fn.to_sym, from: from, to: to)
        .where(**conditions)
        .group(group_label.to_sym)
        .bins(bin_duration_ms)
    end

    def self.query_value(name, reducer, from: nil, to: nil)
      QueryValueBuilder.new(name, reducer, from:, to:)
    end

    def self.query_index(name)
      QueryIndexBuilder.new(name)
    end

    def initialize(key)
      @key = key
    end

    def labels
      @labels ||= info["labels"].to_h
    end

    def name
      @name ||= labels["name"]
    end

    def first_timestamp
      @first_timestamp ||= Time.at(info["firstTimestamp"] / 1000)
    end

    def last_timestamp
      @last_timestamp ||= Time.at(info["lastTimestamp"] / 1000)
    end

    def memory_usage_bytes
      @memory_usage_bytes ||= info["memoryUsage"]
    end

    def total_samples
      @total_samples ||= info["totalSamples"]
    end

    def chunk_size
      @chunk_size ||= info["chunkSize"]
    end

    def chunk_count
      @chunk_count ||= info["chunkCount"]
    end

    def info
      @info ||= Hash[*redis.call("TS.INFO", @key)]
    end

    # def filled_data
    #   # Align to epoch
    #   start_bucket = start_time_ms - (start_time_ms % @agg_duration)
    #   # puts "Filling data from #{start_time_ms} to #{end_time_ms} with agg_duration #{@agg_duration}"
    #   # puts "Start bucket: #{start_bucket}"
    #   Enumerator
    #     .produce(start_bucket) { |t| t + @agg_duration }
    #     .take_while { |t| t < end_time_ms }
    #     .map do |t|
    #     match = data.find { |ts, _| ts == t }
    #     if match
    #       timestamp, val = match
    #       [timestamp, val.to_f]
    #     else
    #       [t, 0]
    #     end
    #   end
    # end

    def value
      @value ||= data.reduce(0) { |sum, (_, value)| sum + value.to_i }
    end

    def pretty_print(pp)
      pp.object_address_group(self) do
        pp.breakable
        pp.text "@key="
        pp.pp key

        pp.breakable
        pp.text "@labels="
        pp.nest(2) do
          pp.breakable
          pp.pp labels
        end

        pp.breakable
        pp.text "@first_timestamp="
        pp.pp first_timestamp

        pp.breakable
        pp.text "@last_timestamp="
        pp.pp last_timestamp

        pp.breakable
        pp.text "@memory_usage_bytes="
        pp.pp memory_usage_bytes

        pp.breakable
        pp.text "@total_samples="
        pp.pp total_samples

        pp.breakable
        pp.text "@chunk_size="
        pp.pp chunk_size

        pp.breakable
        pp.text "@chunk_count="
        pp.pp chunk_count
      end
    end
  end
end
