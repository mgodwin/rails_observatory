require "test_helper"

module RailsObservatory
  class QueryRangeByStringTest < ActiveSupport::TestCase
    # Basic parsing tests

    test "parses basic spec" do
      # 1 hour time range with 60 bins = 60 second bins = 60000ms
      from = Time.now - 1.hour
      to = Time.now
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum", from: from, to: to)

      assert_instance_of RedisTimeSeries::QueryRangeBuilder, query
      assert_equal "name", query.group_label.to_s
      assert_includes query.to_redis_command, "name=request.count"
      assert_includes query.to_redis_command, "compaction=sum"
      assert_includes query.to_redis_command, "AGGREGATION SUM 60000"
    end

    test "parses spec with group label" do
      query = RedisTimeSeries.query_range_by_string("request.latency|avg->60@avg (namespace)")

      assert_instance_of RedisTimeSeries::QueryRangeBuilder, query
      assert_equal "namespace", query.group_label.to_s
      assert_includes query.to_redis_command, "namespace!="
      assert_includes query.to_redis_command, "GROUPBY namespace"
    end

    test "parses all compaction" do
      query = RedisTimeSeries.query_range_by_string("request.latency|all->60@avg")

      command = query.to_redis_command
      # 'all' compaction should use wildcard filter (matches any compaction)
      assert_includes command, "compaction!="
    end

    test "parses different reducers" do
      # 15 minutes with 30 bins = 30 second bins = 30000ms
      from = Time.now - 15.minutes
      to = Time.now
      query = RedisTimeSeries.query_range_by_string("request.latency|max->30@max", from: from, to: to)

      assert_includes query.to_redis_command, "compaction=max"
      assert_includes query.to_redis_command, "AGGREGATION MAX 30000"
    end

    test "parses different bin durations" do
      # 4 hours with 120 bins = 120 second bins = 120000ms
      from = Time.now - 4.hours
      to = Time.now
      query = RedisTimeSeries.query_range_by_string("request.count|sum->120@sum", from: from, to: to)

      assert_includes query.to_redis_command, "AGGREGATION SUM 120000"
    end

    test "calculates bin duration based on time range and target bins" do
      # 24 hours with 60 bins = 24 minute bins = 1440000ms
      from = Time.now - 24.hours
      to = Time.now
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum", from: from, to: to)

      assert_includes query.to_redis_command, "AGGREGATION SUM 1440000"
    end

    test "enforces minimum 1 second bin duration" do
      # 30 seconds with 60 bins would be 500ms, but minimum is 1000ms
      from = Time.now - 30.seconds
      to = Time.now
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum", from: from, to: to)

      assert_includes query.to_redis_command, "AGGREGATION SUM 1000"
    end

    test "falls back to 60 second bins when no time range provided" do
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum")

      assert_includes query.to_redis_command, "AGGREGATION SUM 60000"
    end

    # Group label tests

    test "group label defaults to name" do
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum")

      assert_equal "name", query.group_label.to_s
      assert_includes query.to_redis_command, "GROUPBY name"
    end

    test "custom group label adds exists filter" do
      query = RedisTimeSeries.query_range_by_string("request.latency|avg->60@avg (controller)")

      assert_equal "controller", query.group_label.to_s
      assert_includes query.to_redis_command, "controller!="
      assert_includes query.to_redis_command, "GROUPBY controller"
    end

    test "name group label does not add exists filter" do
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum (name)")

      assert_equal "name", query.group_label.to_s
      # Should not have a duplicate name!= filter
      command = query.to_redis_command
      assert_equal 1, command.scan(/name/).count { |m| m == "name" } - command.scan(/name=/).count
    end

    # Error handling tests

    test "raises on invalid spec" do
      assert_raises ArgumentError do
        RedisTimeSeries.query_range_by_string("invalid")
      end
    end

    test "raises on empty string" do
      assert_raises ArgumentError do
        RedisTimeSeries.query_range_by_string("")
      end
    end

    test "raises on missing compaction" do
      assert_raises ArgumentError do
        RedisTimeSeries.query_range_by_string("request.count->60@sum")
      end
    end

    test "raises on missing bins" do
      assert_raises ArgumentError do
        RedisTimeSeries.query_range_by_string("request.count|sum@sum")
      end
    end

    test "raises on missing reducer" do
      assert_raises ArgumentError do
        RedisTimeSeries.query_range_by_string("request.count|sum->60")
      end
    end
  end
end
