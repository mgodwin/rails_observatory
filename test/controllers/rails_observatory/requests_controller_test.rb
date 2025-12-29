require "test_helper"

module RailsObservatory
  class RequestsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "index renders successfully" do
      get requests_path
      assert_response :success
    end

    test "show renders successfully" do
      get posts_path
      get rails_observatory.request_path(request.request_id)
      assert_response :success
    end

    test "index renders controller action table when data exists" do
      # Insert test data for request.count and request.latency
      action_name = "test_controller#test_action"
      timestamp = Time.now

      # Record a request count - this creates the _sum compaction
      RedisTimeSeries.increment("request.count", at: timestamp, labels: {action: action_name})

      # Record a latency timing - this creates the _avg compaction
      RedisTimeSeries.distribution("request.latency", 150.5, at: timestamp, labels: {action: action_name})

      # Track keys for cleanup (main series + compactions + init locks)
      count_digest = Digest::SHA1.hexdigest(["action", action_name].join).slice(0, 20)
      latency_digest = Digest::SHA1.hexdigest(["action", action_name].join).slice(0, 20)

      @test_keys += [
        "request.count:#{count_digest}",
        "request.count:#{count_digest}_sum",
        "init:request.count:#{count_digest}",
        "request.latency:#{latency_digest}",
        "request.latency:#{latency_digest}_avg",
        "request.latency:#{latency_digest}_min",
        "request.latency:#{latency_digest}_max",
        "init:request.latency:#{latency_digest}"
      ]

      get requests_path
      assert_response :success

      # Verify the "By Controller Action" section is rendered
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "By Controller Action"
        assert_select "table" do
          assert_select "th", text: "Controller Action"
          assert_select "th", text: "Requests"
          assert_select "th", text: "Avg Latency"
        end
      end
    end

    test "index does not render controller action table when controller_action param is present" do
      get requests_path(controller_action: "posts#index")
      assert_response :success

      # The "By Controller Action" section should not be rendered
      assert_select "section.layout-requests_index-by_controller", count: 0
    end
  end
end
