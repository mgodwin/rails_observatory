require "test_helper"

module RailsObservatory
  class QueryIndexBuilderTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis

      # Track test keys for cleanup
      @test_keys = []

      # Create test time series with different labels for testing
      # QueryIndexBuilder looks for compaction: true, so we set that
      create_test_series("ts:test:idx:posts_index", {
        "name" => "test_idx_requests",
        "compaction" => "true",
        "controller" => "posts",
        "action" => "index",
        "status" => "200"
      })

      create_test_series("ts:test:idx:posts_show", {
        "name" => "test_idx_requests",
        "compaction" => "true",
        "controller" => "posts",
        "action" => "show",
        "status" => "200"
      })

      create_test_series("ts:test:idx:users_index", {
        "name" => "test_idx_requests",
        "compaction" => "true",
        "controller" => "users",
        "action" => "index",
        "status" => "500"
      })

      # Create a series without compaction label for testing false filter
      create_test_series("ts:test:idx:raw_data", {
        "name" => "test_idx_requests",
        "controller" => "admin"
      })

      # Add some data to the series
      ts_ms = (Time.now.to_f * 1000).to_i
      @redis.call("TS.ADD", "ts:test:idx:posts_index", ts_ms, 1)
      @redis.call("TS.ADD", "ts:test:idx:posts_show", ts_ms, 1)
      @redis.call("TS.ADD", "ts:test:idx:users_index", ts_ms, 1)
      @redis.call("TS.ADD", "ts:test:idx:raw_data", ts_ms, 1)
    end

    def teardown
      # Clean up only our test keys
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    # Initialization tests

    test "initializes with name" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
      assert_instance_of RedisTimeSeries::QueryIndexBuilder, builder
    end

    test "initializes with compaction true by default" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
      command = builder.to_redis_command

      assert_includes command, "compaction!="
    end

    # Chainable method tests

    test "where filters by labels" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
        .where(controller: "posts")

      command = builder.to_redis_command
      assert_includes command, "controller=posts"
    end

    test "where returns a clone" do
      original = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
      filtered = original.where(controller: "posts")

      assert_not_same original, filtered
      # Original should not have the new filter
      assert_not_includes original.to_redis_command, "controller=posts"
    end

    test "where can be chained multiple times" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
        .where(controller: "posts")
        .where(action: "index")

      command = builder.to_redis_command
      assert_includes command, "controller=posts"
      assert_includes command, "action=index"
    end

    # Command generation tests

    test "to_redis_args generates correct TS.QUERYINDEX command" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")

      args = builder.to_redis_args
      assert_equal "TS.QUERYINDEX", args[0]
      assert_includes args, "name=test_idx_requests"
    end

    test "to_redis_command returns space-separated string" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")

      command = builder.to_redis_command
      assert_instance_of String, command
      assert command.start_with?("TS.QUERYINDEX")
    end

    # Filter syntax tests

    test "where with true generates exists filter" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
        .where(action: true)

      command = builder.to_redis_command
      assert_includes command, "action!="
    end

    test "where with false generates not exists filter" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
        .where(custom_label: false)

      command = builder.to_redis_command
      # Should generate "custom_label=" (without value means doesn't exist)
      assert_match(/custom_label=(?!\S)/, command)
    end

    test "where with array generates multi-value filter" do
      builder = RedisTimeSeries::QueryIndexBuilder.new("test_idx_requests")
        .where(action: ["index", "show"])

      command = builder.to_redis_command
      assert_includes command, "action=(index,show)"
    end

    # Terminal method tests

    test "each yields RedisTimeSeries objects" do
      series = []
      RedisTimeSeries.query_index("test_idx_requests")
        .where(controller: "posts")
        .each { |ts| series << ts }

      assert series.any?
      series.each do |ts|
        assert_instance_of RedisTimeSeries, ts
        assert ts.respond_to?(:key)
        assert ts.respond_to?(:labels)
      end
    end

    test "to_a returns array of RedisTimeSeries objects" do
      result = RedisTimeSeries.query_index("test_idx_requests")
        .where(controller: "posts")
        .to_a

      assert_instance_of Array, result
      result.each do |ts|
        assert_instance_of RedisTimeSeries, ts
      end
    end

    test "filters correctly by label values" do
      # Should find only posts controller series
      posts_series = RedisTimeSeries.query_index("test_idx_requests")
        .where(controller: "posts")
        .to_a

      assert_equal 2, posts_series.size
      posts_series.each do |ts|
        assert_equal "posts", ts.labels["controller"]
      end
    end

    test "filters correctly by multiple labels" do
      # Should find only posts#index
      series = RedisTimeSeries.query_index("test_idx_requests")
        .where(controller: "posts", action: "index")
        .to_a

      assert_equal 1, series.size
      assert_equal "posts", series.first.labels["controller"]
      assert_equal "index", series.first.labels["action"]
    end

    test "returns empty array when no matches" do
      series = RedisTimeSeries.query_index("test_idx_requests")
        .where(controller: "nonexistent")
        .to_a

      assert_empty series
    end

    test "handles nil response gracefully" do
      # Query for a name that doesn't exist
      series = []
      RedisTimeSeries.query_index("nonexistent_metric")
        .each { |ts| series << ts }

      assert_empty series
    end

    private

    def create_test_series(key, labels)
      label_args = labels.to_a.flatten
      @redis.call("TS.CREATE", key, "LABELS", *label_args)
      @test_keys << key
    end
  end
end
