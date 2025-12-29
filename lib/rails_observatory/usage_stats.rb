module RailsObservatory
  class UsageStats
    include RedisConnection

    CATEGORIES = {
      traces: {
        patterns: ["rt:*", "jt:*"],
        description: "Request and job trace documents"
      },
      logs_events: {
        patterns: ["rt_events:*", "rt_logs:*", "jt_events:*", "jt_logs:*"],
        description: "Compressed logs and events"
      },
      errors: {
        patterns: ["error:*", "error_causes:*", "error_trace:*", "error_source_extracts:*"],
        description: "Error records and stack traces"
      },
      mail: {
        patterns: ["maildelivery:*", "maildelivery_mail:*"],
        description: "Mail delivery records"
      },
      time_series: {
        description: "Metrics and time series data"
      },
      indexes: {
        names: ["rt-idx", "jt-idx", "error-idx", "maildelivery-idx"],
        description: "Full-text search indexes"
      }
    }.freeze

    MAX_SAMPLES = 100

    def memory_info
      @memory_info ||= parse_memory_info
    end

    def total_used_bytes
      memory_info["used_memory"].to_i
    end

    def max_memory_bytes
      configured_max = memory_info["maxmemory"].to_i
      return configured_max if configured_max > 0

      rails_config_max || env_max
    end

    def remaining_capacity
      return nil unless max_memory_bytes
      [max_memory_bytes - total_used_bytes, 0].max
    end

    def capacity_percentage
      return nil unless max_memory_bytes && max_memory_bytes > 0
      (total_used_bytes.to_f / max_memory_bytes * 100).round(1)
    end

    def category_stats
      @category_stats ||= calculate_all_categories
    end

    def total_keys
      @total_keys ||= redis.call("DBSIZE")
    end

    private

    def calculate_all_categories
      {
        traces: calculate_pattern_memory(CATEGORIES[:traces][:patterns]),
        logs_events: calculate_pattern_memory(CATEGORIES[:logs_events][:patterns]),
        errors: calculate_pattern_memory(CATEGORIES[:errors][:patterns]),
        mail: calculate_pattern_memory(CATEGORIES[:mail][:patterns]),
        time_series: calculate_time_series_memory,
        indexes: calculate_index_memory
      }
    end

    def calculate_pattern_memory(patterns)
      total_bytes = 0
      key_count = 0
      sample_count = 0
      sampled_bytes = 0

      patterns.each do |pattern|
        cursor = "0"
        loop do
          cursor, keys = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 100)
          key_count += keys.size

          # Sample keys for memory estimation
          keys_to_sample = if sample_count < MAX_SAMPLES
            keys.sample([MAX_SAMPLES - sample_count, keys.size].min)
          else
            []
          end

          keys_to_sample.each do |key|
            mem = redis.call("MEMORY", "USAGE", key)
            if mem
              sampled_bytes += mem
              sample_count += 1
            end
          end

          break if cursor == "0"
        end
      end

      # Extrapolate from samples if needed
      if sample_count > 0 && sample_count < key_count
        avg_per_key = sampled_bytes.to_f / sample_count
        total_bytes = (avg_per_key * key_count).to_i
      else
        total_bytes = sampled_bytes
      end

      {bytes: total_bytes, key_count: key_count, sampled: sample_count < key_count && key_count > 0}
    end

    def calculate_time_series_memory
      total_bytes = 0
      key_count = 0

      # Time series keys follow pattern: metric.name:hash or metric.name:hash_compaction
      # Common prefixes: request.*, job.*
      ts_patterns = ["request.*", "job.*"]

      ts_patterns.each do |pattern|
        cursor = "0"
        loop do
          cursor, keys = redis.call("SCAN", cursor, "MATCH", pattern, "COUNT", 100)

          keys.each do |key|
            begin
              # Try to get TS.INFO - if it succeeds, it's a time series
              info = redis.call("TS.INFO", key)
              info_hash = Hash[*info]
              total_bytes += info_hash["memoryUsage"].to_i
              key_count += 1
            rescue
              # Not a time series key, skip
            end
          end

          break if cursor == "0"
        end
      end

      {bytes: total_bytes, key_count: key_count, sampled: false}
    end

    def calculate_index_memory
      total_bytes = 0
      index_details = {}

      CATEGORIES[:indexes][:names].each do |idx_name|
        begin
          info = redis.call("FT.INFO", idx_name)
          info_hash = Hash[*info]
          # FT.INFO returns inverted_sz_mb as a float in MB
          bytes = (info_hash["inverted_sz_mb"].to_f * 1024 * 1024).to_i
          # Also add doc_table_size_mb if available
          bytes += (info_hash["doc_table_size_mb"].to_f * 1024 * 1024).to_i
          index_details[idx_name] = bytes
          total_bytes += bytes
        rescue
          # Index may not exist
        end
      end

      {bytes: total_bytes, index_details: index_details, key_count: index_details.size, sampled: false}
    end

    def parse_memory_info
      redis.call("INFO", "memory")
        .split("\r\n")
        .drop(1)
        .map { |line| line.split(":") }
        .to_h
    end

    def rails_config_max
      config = Rails.configuration.rails_observatory
      config.respond_to?(:max_memory) ? config.max_memory : nil
    end

    def env_max
      ENV["RAILS_OBSERVATORY_MAX_MEMORY"]&.to_i&.then { |v| v > 0 ? v : nil }
    end
  end
end
