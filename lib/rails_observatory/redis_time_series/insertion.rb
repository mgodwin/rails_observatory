require "digest"
module RailsObservatory
  class RedisTimeSeries
    module Insertion
      def distribution(name, value, at: Time.now, labels: {})
        prefixed_name = defined?(self::PREFIX) ? [self::PREFIX, name].join(".") : name
        timestamp_ms = (at.to_f * 1000).to_i
        labels_flat = labels.sort.flatten.map(&:to_s)
        digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
        ts_name = "#{prefixed_name}:#{digest}"

        # Cold path: create series with compactions if needed
        if redis.call("EXISTS", ts_name).zero?
          if redis.call("SETNX", "init:#{ts_name}", 1) == 1
            redis.pipelined do |r|
              r.call("TS.CREATE", ts_name, "RETENTION", 10_000, "CHUNK_SIZE", 4_096)
              %w[avg min max].each do |agg|
                comp_key = "#{ts_name}_#{agg}"
                r.call("TS.CREATE", comp_key, "RETENTION", 31_536_000_000, "CHUNK_SIZE", 4_096,
                  "LABELS", "name", prefixed_name, "compaction", agg, *labels_flat)
                r.call("TS.CREATERULE", ts_name, comp_key, "AGGREGATION", agg, 10_000)
              end
            end
          end
        end

        redis.call("TS.ADD", ts_name, timestamp_ms, value, "ON_DUPLICATE", "LAST")
      end

      alias_method :record_timing, :distribution

      def increment(name, at: Time.now, labels: {})
        timestamp_ms = (at.to_f * 1000).to_i
        labels_flat = labels.sort.flatten.map(&:to_s)
        digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
        ts_name = "#{name}:#{digest}"
        comp_key = "#{ts_name}_sum"

        # Cold path: create series with compaction if needed
        if redis.call("EXISTS", ts_name).zero?
          if redis.call("SETNX", "init:#{ts_name}", 1) == 1
            redis.pipelined do |r|
              r.call("TS.CREATE", ts_name, "RETENTION", 10_000, "CHUNK_SIZE", 4_096)
              r.call("TS.CREATE", comp_key, "RETENTION", 31_536_000_000, "CHUNK_SIZE", 4_096,
                "LABELS", "name", name, "compaction", "sum", *labels_flat)
              r.call("TS.CREATERULE", ts_name, comp_key, "AGGREGATION", "sum", 10_000)
            end
          end
        end

        redis.call("TS.ADD", ts_name, timestamp_ms, 1, "ON_DUPLICATE", "SUM")
      end

      alias_method :record_occurrence, :increment
    end
  end
end
