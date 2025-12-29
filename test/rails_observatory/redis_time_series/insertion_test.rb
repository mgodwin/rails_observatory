require "test_helper"

module RailsObservatory
  class InsertionTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
      @base_time = Time.now
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
      # Clean up init locks
      @test_keys.each { |key| @redis.call("DEL", "init:#{key}") }
    end

    # increment tests

    test "increment creates time series on first call (cold path)" do
      name = "test.increment.cold"
      labels = { action: "index", controller: "posts" }

      RedisTimeSeries.increment(name, at: @base_time, labels: labels)

      # Find the created keys
      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"
      comp_key = "#{ts_name}_sum"

      @test_keys << ts_name
      @test_keys << comp_key

      # Verify raw series exists
      assert_equal 1, @redis.call("EXISTS", ts_name), "Raw time series should exist"

      # Verify compaction series exists with correct labels
      assert_equal 1, @redis.call("EXISTS", comp_key), "Compaction series should exist"

      info = @redis.call("TS.INFO", comp_key)
      labels_hash = parse_ts_info_labels(info)
      assert_equal "sum", labels_hash["compaction"]
      assert_equal "index", labels_hash["action"]
      assert_equal "posts", labels_hash["controller"]
    end

    test "increment adds value on hot path" do
      name = "test.increment.hot"
      labels = { action: "show" }

      # First call creates the series
      RedisTimeSeries.increment(name, at: @base_time, labels: labels)

      # Second call should use hot path
      RedisTimeSeries.increment(name, at: @base_time + 1.second, labels: labels)

      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"
      comp_key = "#{ts_name}_sum"

      @test_keys << ts_name
      @test_keys << comp_key

      # Get the latest value - should reflect multiple increments
      result = @redis.call("TS.GET", ts_name)
      assert result, "Should have data in the series"
    end

    test "increment uses ON_DUPLICATE SUM for same timestamp" do
      name = "test.increment.duplicate"
      labels = { action: "create" }
      timestamp = @base_time

      # Multiple increments at the same timestamp should sum
      3.times { RedisTimeSeries.increment(name, at: timestamp, labels: labels) }

      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"
      comp_key = "#{ts_name}_sum"

      @test_keys << ts_name
      @test_keys << comp_key

      result = @redis.call("TS.GET", ts_name)
      assert_equal 3, result[1].to_i, "Value should be sum of all increments"
    end

    test "increment creates different series for different labels" do
      name = "test.increment.labels"
      labels1 = { action: "index" }
      labels2 = { action: "show" }

      RedisTimeSeries.increment(name, at: @base_time, labels: labels1)
      RedisTimeSeries.increment(name, at: @base_time, labels: labels2)

      # Calculate both keys
      digest1 = Digest::SHA1.hexdigest(labels1.sort.flatten.map(&:to_s).join).slice(0, 20)
      digest2 = Digest::SHA1.hexdigest(labels2.sort.flatten.map(&:to_s).join).slice(0, 20)

      ts_name1 = "#{name}:#{digest1}"
      ts_name2 = "#{name}:#{digest2}"

      @test_keys << ts_name1
      @test_keys << "#{ts_name1}_sum"
      @test_keys << ts_name2
      @test_keys << "#{ts_name2}_sum"

      assert_not_equal ts_name1, ts_name2, "Different labels should create different series"
      assert_equal 1, @redis.call("EXISTS", ts_name1)
      assert_equal 1, @redis.call("EXISTS", ts_name2)
    end

    # distribution tests

    test "distribution creates time series with avg/min/max compactions on first call" do
      name = "test.distribution.cold"
      labels = { action: "index", controller: "posts" }

      RedisTimeSeries.distribution(name, 100.5, at: @base_time, labels: labels)

      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"

      @test_keys << ts_name
      %w[avg min max].each { |agg| @test_keys << "#{ts_name}_#{agg}" }

      # Verify raw series exists
      assert_equal 1, @redis.call("EXISTS", ts_name), "Raw time series should exist"

      # Verify all compaction series exist
      %w[avg min max].each do |agg|
        comp_key = "#{ts_name}_#{agg}"
        assert_equal 1, @redis.call("EXISTS", comp_key), "#{agg} compaction should exist"

        info = @redis.call("TS.INFO", comp_key)
        labels_hash = parse_ts_info_labels(info)
        assert_equal agg, labels_hash["compaction"]
        assert_equal name, labels_hash["name"]
      end
    end

    test "distribution adds value on hot path" do
      name = "test.distribution.hot"
      labels = { action: "show" }

      # First call creates the series
      RedisTimeSeries.distribution(name, 50.0, at: @base_time, labels: labels)

      # Second call should use hot path
      RedisTimeSeries.distribution(name, 75.0, at: @base_time + 1.second, labels: labels)

      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"

      @test_keys << ts_name
      %w[avg min max].each { |agg| @test_keys << "#{ts_name}_#{agg}" }

      result = @redis.call("TS.GET", ts_name)
      assert_equal 75.0, result[1].to_f, "Should have latest value"
    end

    test "distribution uses ON_DUPLICATE LAST for same timestamp" do
      name = "test.distribution.duplicate"
      labels = { action: "create" }
      timestamp = @base_time

      RedisTimeSeries.distribution(name, 10.0, at: timestamp, labels: labels)
      RedisTimeSeries.distribution(name, 20.0, at: timestamp, labels: labels)
      RedisTimeSeries.distribution(name, 30.0, at: timestamp, labels: labels)

      labels_flat = labels.sort.flatten.map(&:to_s)
      digest = Digest::SHA1.hexdigest(labels_flat.join).slice(0, 20)
      ts_name = "#{name}:#{digest}"

      @test_keys << ts_name
      %w[avg min max].each { |agg| @test_keys << "#{ts_name}_#{agg}" }

      result = @redis.call("TS.GET", ts_name)
      assert_equal 30.0, result[1].to_f, "Value should be last written (LAST policy)"
    end

    test "distribution creates different series for different labels" do
      name = "test.distribution.labels"
      labels1 = { action: "index" }
      labels2 = { action: "show" }

      RedisTimeSeries.distribution(name, 100.0, at: @base_time, labels: labels1)
      RedisTimeSeries.distribution(name, 200.0, at: @base_time, labels: labels2)

      digest1 = Digest::SHA1.hexdigest(labels1.sort.flatten.map(&:to_s).join).slice(0, 20)
      digest2 = Digest::SHA1.hexdigest(labels2.sort.flatten.map(&:to_s).join).slice(0, 20)

      ts_name1 = "#{name}:#{digest1}"
      ts_name2 = "#{name}:#{digest2}"

      @test_keys << ts_name1
      @test_keys << ts_name2
      %w[avg min max].each do |agg|
        @test_keys << "#{ts_name1}_#{agg}"
        @test_keys << "#{ts_name2}_#{agg}"
      end

      assert_not_equal ts_name1, ts_name2
      assert_equal 1, @redis.call("EXISTS", ts_name1)
      assert_equal 1, @redis.call("EXISTS", ts_name2)
    end

    # alias tests

    test "record_occurrence is an alias for increment" do
      assert_equal RedisTimeSeries.method(:record_occurrence), RedisTimeSeries.method(:increment)
    end

    test "record_timing is an alias for distribution" do
      assert_equal RedisTimeSeries.method(:record_timing), RedisTimeSeries.method(:distribution)
    end

    # empty labels tests

    test "increment works with empty labels" do
      name = "test.increment.nolabels"

      RedisTimeSeries.increment(name, at: @base_time, labels: {})

      digest = Digest::SHA1.hexdigest("").slice(0, 20)
      ts_name = "#{name}:#{digest}"
      comp_key = "#{ts_name}_sum"

      @test_keys << ts_name
      @test_keys << comp_key

      assert_equal 1, @redis.call("EXISTS", ts_name)
    end

    test "distribution works with empty labels" do
      name = "test.distribution.nolabels"

      RedisTimeSeries.distribution(name, 42.0, at: @base_time, labels: {})

      digest = Digest::SHA1.hexdigest("").slice(0, 20)
      ts_name = "#{name}:#{digest}"

      @test_keys << ts_name
      %w[avg min max].each { |agg| @test_keys << "#{ts_name}_#{agg}" }

      assert_equal 1, @redis.call("EXISTS", ts_name)
    end

    private

    def parse_ts_info_labels(info)
      # TS.INFO returns an array, find the labels section
      labels_idx = info.index("labels")
      return {} unless labels_idx

      labels_array = info[labels_idx + 1]
      labels_array.to_h { |pair| [pair[0], pair[1]] }
    end
  end
end
