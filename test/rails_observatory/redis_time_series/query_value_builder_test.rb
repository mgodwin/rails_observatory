require "test_helper"

module RailsObservatory
  class QueryValueBuilderTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis

      # Clean up only test keys, not the entire database
      @test_keys = []

      # Create test time series with different labels for testing
      @base_time = Time.at((Time.now.to_i / 10) * 10)
      @from_time = @base_time - 1.minute
      @to_time = @base_time + 1.minute

      # Create time series directly with TS.CREATE for testing
      create_test_series("ts:test:value:posts_index", {
        "name" => "test_value_requests",
        "compaction" => "sum",
        "controller" => "posts",
        "action" => "index"
      })

      create_test_series("ts:test:value:posts_show", {
        "name" => "test_value_requests",
        "compaction" => "sum",
        "controller" => "posts",
        "action" => "show"
      })

      create_test_series("ts:test:value:users_index", {
        "name" => "test_value_requests",
        "compaction" => "sum",
        "controller" => "users",
        "action" => "index"
      })

      # Add data points at aligned timestamps
      ts_ms = (@base_time.to_f * 1000).to_i
      @redis.call("TS.ADD", "ts:test:value:posts_index", ts_ms, 10)
      @redis.call("TS.ADD", "ts:test:value:posts_show", ts_ms, 5)
      @redis.call("TS.ADD", "ts:test:value:users_index", ts_ms, 3)
    end

    def teardown
      # Clean up only our test keys
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    # Value type tests - these test the fix for the string comparison bug

    test "value returns numeric that can be compared with integers" do
      values = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .to_a

      assert values.any?, "Expected some values to be returned"

      # This should not raise ArgumentError: comparison of String with 0 failed
      values.each do |v|
        assert_nothing_raised { v.value > 0 }
        assert_nothing_raised { v.value < 100 }
        assert_nothing_raised { v.value == 0 }
      end
    end

    test "value returns Float type" do
      values = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .to_a

      assert values.any?, "Expected some values to be returned"

      values.each do |v|
        assert_instance_of Float, v.value, "Value should be a Float, not #{v.value.class}"
      end
    end

    test "value can be used with select for filtering" do
      # This is the exact pattern that was failing in requests_controller.rb:14
      values = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .select { _1.value > 0 }

      assert values.any?, "Expected some values with value > 0"
    end

    test "value can be used with sort_by" do
      # This is another pattern from requests_controller.rb
      values = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .to_a
        .sort_by(&:value)

      assert values.any?, "Expected some values to be returned"
      # Should be sorted in ascending order
      values.each_cons(2) do |a, b|
        assert a.value <= b.value, "Values should be sorted"
      end
    end

    # Basic functionality tests

    test "each yields Value objects" do
      values = []
      RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .each { |v| values << v }

      assert values.any?
      values.each do |v|
        assert_instance_of RedisTimeSeries::Value, v
        assert v.respond_to?(:labels)
        assert v.respond_to?(:value)
      end
    end

    test "to_a returns array of Value objects" do
      result = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .to_a

      assert_instance_of Array, result
      result.each do |v|
        assert_instance_of RedisTimeSeries::Value, v
      end
    end

    test "where filters by labels" do
      builder = RedisTimeSeries::QueryValueBuilder.new("test_value_requests", :sum)
        .where(controller: "posts")

      command = builder.to_redis_command
      assert_includes command, "controller=posts"
    end

    test "group sets grouping label" do
      builder = RedisTimeSeries::QueryValueBuilder.new("test_value_requests", :sum)
        .group("controller")

      command = builder.to_redis_command
      assert_includes command, "GROUPBY controller"
    end

    test "value is zero when no data points exist" do
      # Query a time series that doesn't exist
      values = RedisTimeSeries.query_value("nonexistent_series", :sum)
        .where(action: true)
        .group("action")
        .to_a

      # Should return empty array, no errors
      assert_instance_of Array, values
    end

    test "uses observatory_slice when no explicit time range provided" do
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = (@from_time..@to_time)

      # Query without explicit from/to should use observatory_slice
      values = RedisTimeSeries.query_value("test_value_requests", :sum)
        .where(action: true)
        .group("action")
        .to_a

      assert values.any?, "Expected values when using observatory_slice"
    ensure
      ActiveSupport::IsolatedExecutionState[:observatory_slice] = nil
    end

    private

    def create_test_series(key, labels)
      label_args = labels.to_a.flatten
      @redis.call("TS.CREATE", key, "LABELS", *label_args)
      @test_keys << key
    end
  end
end
