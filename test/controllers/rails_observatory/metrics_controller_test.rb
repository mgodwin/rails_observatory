require "test_helper"

module RailsObservatory
  class MetricsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []

      # Create test metric series directly with proper labels.
      # We skip the Insertion module (which uses raw series + compaction rules) to avoid
      # timing issues where the compaction bucket hasn't closed yet.
      @counter_metric = "test.counter"
      @distribution_metric = "test.latency"

      # Counter: one sum-compaction series
      @counter_key = "#{@counter_metric}:testkey001_sum"
      @redis.call("TS.CREATE", @counter_key, "LABELS",
        "name", @counter_metric,
        "compaction", "sum",
        "env", "test")
      @test_keys << @counter_key

      # Distribution: avg/min/max compaction series
      %w[avg min max].each do |agg|
        key = "#{@distribution_metric}:testkey002_#{agg}"
        @redis.call("TS.CREATE", key, "LABELS",
          "name", @distribution_metric,
          "compaction", agg,
          "env", "test")
        @test_keys << key
      end

      # Add data points spanning the last hour
      now_ms = (Time.now.to_f * 1000).to_i
      [60_000, 30_000, 0].each_with_index do |offset_ms, i|
        ts = now_ms - offset_ms
        @redis.call("TS.ADD", @counter_key, ts, (i + 1) * 5)
        @redis.call("TS.ADD", "#{@distribution_metric}:testkey002_avg", ts, 100 + i * 10)
      end
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "index renders successfully" do
      get metrics_path
      assert_response :success
    end

    test "index shows summary stat labels" do
      get metrics_path
      assert_response :success
      assert_select "dt", text: "Unique Metrics"
      assert_select "dt", text: "Time Series"
      assert_select "dt", text: "Counters"
      assert_select "dt", text: "Distributions"
    end

    test "index counts test series in summary stats" do
      get metrics_path
      assert_response :success
      # At least our test metrics are counted
      assert_select "dl dd", minimum: 4
    end

    test "index shows placeholder when no metric selected" do
      get metrics_path
      assert_response :success
      assert_select "section.metric-chart-placeholder"
    end

    test "index shows metric controls when metric is selected" do
      get metrics_path(metric: @counter_metric)
      assert_response :success
      assert_select ".metric-controls"
      assert_select "label", text: "Aggregation"
      assert_select "label", text: "Group By"
      assert_select "label", text: "Chart Type"
    end

    test "index renders bar chart for counter metric" do
      get metrics_path(metric: @counter_metric)
      assert_response :success
      assert_select "[data-controller='bar-chart']"
      assert_select "[data-bar-chart-name-value='#{@counter_metric}']"
    end

    test "index renders area chart for distribution metric" do
      get metrics_path(metric: @distribution_metric)
      assert_response :success
      assert_select "[data-controller='area-chart']"
      assert_select "[data-area-chart-name-value='#{@distribution_metric}']"
    end

    test "index chart data attribute contains series array" do
      get metrics_path(metric: @counter_metric)
      assert_response :success
      chart_div = css_select("[data-bar-chart-initial-data-value]").first
      assert_not_nil chart_div, "Expected bar chart with initial-data-value attribute"
      data = JSON.parse(chart_div["data-bar-chart-initial-data-value"])
      assert_instance_of Array, data
      assert data.any?, "Expected non-empty chart data"
      data.each do |series|
        assert series.key?("name"), "Each series should have a name"
        assert series.key?("data"), "Each series should have data"
        assert_instance_of Array, series["data"]
      end
    end

    test "index chart data has correct metric name" do
      get metrics_path(metric: @counter_metric)
      assert_response :success
      chart_div = css_select("[data-bar-chart-initial-data-value]").first
      data = JSON.parse(chart_div["data-bar-chart-initial-data-value"])
      names = data.map { |s| s["name"] }
      assert_includes names, @counter_metric
    end

    test "index uses explicit compaction when provided" do
      get metrics_path(metric: @counter_metric, compaction: "sum")
      assert_response :success
      assert_select "[data-controller='bar-chart']"
    end

    test "index uses explicit chart_type when provided" do
      get metrics_path(metric: @counter_metric, chart_type: "area")
      assert_response :success
      assert_select "[data-controller='area-chart']"
    end

    test "index applies stacked attribute when group_by is set" do
      get metrics_path(metric: @counter_metric, group_by: "env")
      assert_response :success
      chart_div = css_select("[data-bar-chart-stacked-value]").first
      assert_not_nil chart_div, "Expected stacked attribute when group_by is set"
    end

    test "autocomplete returns JSON array of metric names" do
      get autocomplete_metrics_path
      assert_response :success
      assert_equal "application/json", response.content_type.split(";").first
      names = JSON.parse(response.body)
      assert_instance_of Array, names
      assert_includes names, @counter_metric
    end

    test "autocomplete returns only sum and avg compaction metrics" do
      get autocomplete_metrics_path
      names = JSON.parse(response.body)
      # Distribution metric has avg compaction so should appear
      assert_includes names, @distribution_metric
    end

    test "autocomplete returns sorted unique names" do
      get autocomplete_metrics_path
      names = JSON.parse(response.body)
      assert_equal names.sort.uniq, names
    end

    test "labels returns JSON array for a metric" do
      get labels_metric_path(@counter_metric)
      assert_response :success
      assert_equal "application/json", response.content_type.split(";").first
      labels = JSON.parse(response.body)
      assert_instance_of Array, labels
    end

    test "labels excludes reserved label keys" do
      get labels_metric_path(@counter_metric)
      labels = JSON.parse(response.body)
      assert_not_includes labels, "name"
      assert_not_includes labels, "compaction"
      assert_not_includes labels, "__source__"
    end

    test "labels includes non-reserved labels" do
      get labels_metric_path(@counter_metric)
      labels = JSON.parse(response.body)
      assert_includes labels, "env"
    end
  end
end
