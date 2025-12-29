require "test_helper"

module RailsObservatory
  class QueryRangeByStringTest < ActiveSupport::TestCase
    # Basic parsing tests

    test "parses basic spec" do
      query = RedisTimeSeries.query_range_by_string("request.count|sum->60@sum")

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
      query = RedisTimeSeries.query_range_by_string("request.latency|max->30@max")

      assert_includes query.to_redis_command, "compaction=max"
      assert_includes query.to_redis_command, "AGGREGATION MAX 30000"
    end

    test "parses different bin durations" do
      query = RedisTimeSeries.query_range_by_string("request.count|sum->120@sum")

      assert_includes query.to_redis_command, "AGGREGATION SUM 120000"
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
