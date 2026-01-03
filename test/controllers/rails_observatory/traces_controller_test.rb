require "test_helper"

module RailsObservatory
  class TracesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "overview shows unpermitted params in red" do
      # Make request with unpermitted params to trigger event
      post unpermitted_params_scenarios_path, params: {
        post: {title: "Valid", hacker_field: "rejected"}
      }
      request_id = request.request_id
      sleep 0.1 # Wait for async worker

      # View the trace via traces controller (uses _overview.html.erb)
      get trace_by_type_path(type: "rt", id: request_id, tab: "overview")
      assert_response :success

      # Verify unpermitted param is styled with error color
      assert_select "section h3", text: "Parameters"
      assert_select "section dl dt", /post\.hacker_field/ do |elements|
        assert_match(/var\(--error\)/, elements.first["style"])
      end

      # Verify permitted param is NOT styled with error color
      assert_select "section dl dt", /post\.title/ do |elements|
        refute_match(/var\(--error\)/, elements.first["style"])
      end
    end

    test "overview shows flattened nested params" do
      post unpermitted_params_scenarios_path, params: {
        post: {title: "Test", nested: {deep: "value"}}
      }
      request_id = request.request_id
      sleep 0.1

      get trace_by_type_path(type: "rt", id: request_id, tab: "overview")
      assert_response :success

      # Verify nested params are flattened with dot notation
      assert_select "section dl dt", /post\.nested\.deep/
    end

    test "overview shows params normally when none are unpermitted" do
      get posts_path
      request_id = request.request_id
      sleep 0.1

      get trace_by_type_path(type: "rt", id: request_id, tab: "overview")
      assert_response :success

      # Verify params exist but none have error styling
      assert_select "dt[style*='var(--error)']", count: 0
    end

    test "overview shows response headers" do
      get success_scenarios_path
      request_id = request.request_id
      sleep 0.1

      get trace_by_type_path(type: "rt", id: request_id, tab: "overview")
      assert_response :success

      # Verify response headers section exists
      assert_select "details summary", /Response Headers/

      # Verify common response headers are displayed
      assert_select "details dl dt", /Content-Type/i
    end
  end
end
