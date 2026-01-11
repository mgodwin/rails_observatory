require "test_helper"

module RailsObservatory
  class RequestTracesControllerTest < ActionDispatch::IntegrationTest
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

      # View the trace via request traces controller (uses _overview.html.erb)
      get request_trace_path(id: request_id, tab: "overview")
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

      get request_trace_path(id: request_id, tab: "overview")
      assert_response :success

      # Verify nested params are flattened with dot notation
      assert_select "section dl dt", /post\.nested\.deep/
    end

    test "overview shows params normally when none are unpermitted" do
      get posts_path
      request_id = request.request_id
      sleep 0.1

      get request_trace_path(id: request_id, tab: "overview")
      assert_response :success

      # Verify params exist but none have error styling
      assert_select "dt[style*='var(--error)']", count: 0
    end

    test "overview shows response headers" do
      get success_scenarios_path
      request_id = request.request_id
      sleep 0.1

      get request_trace_path(id: request_id, tab: "overview")
      assert_response :success

      # Verify response headers section exists
      assert_select "details summary", /Response Headers/

      # Verify common response headers are displayed
      assert_select "details dl dt", /Content-Type/i
    end

    test "tabs are contextual - only shows available tabs" do
      get success_scenarios_path
      request_id = request.request_id
      sleep 0.1

      get request_trace_path(id: request_id)
      assert_response :success

      # These tabs should always appear in page tabs nav
      assert_select "nav.tabs a", text: "Overview"
      assert_select "nav.tabs a", text: "Events"
      assert_select "nav.tabs a", text: "Logs"

      # Mail, Jobs, Errors tabs should not appear in page tabs for a simple success request
      assert_select "nav.tabs a", text: "Mail", count: 0
      assert_select "nav.tabs a", text: "Jobs", count: 0
      assert_select "nav.tabs a", text: "Errors", count: 0
    end

    test "redirects to overview when accessing unavailable tab" do
      get success_scenarios_path
      request_id = request.request_id
      sleep 0.1

      get request_trace_path(id: request_id, tab: "mail")
      assert_redirected_to request_trace_path(id: request_id, tab: "overview")
    end

    test "overview shows rate limiting information when request was blocked" do
      # Clear any existing rate limit counter
      Rails.cache.clear

      # First request succeeds (under the limit)
      get rate_limited_scenarios_path
      assert_response :success

      # Second request exceeds the limit and triggers the rate_limit.action_controller event
      get rate_limited_scenarios_path
      assert_response :too_many_requests
      request_id = request.request_id
      sleep 0.1

      # View the trace via request traces controller
      get request_trace_path(id: request_id, tab: "overview")
      assert_response :success

      # Verify rate limiting section is displayed
      assert_select "section.rate-limit-section h3", /Request Rejected.*Rate Limited/
      assert_select "section.rate-limit-section p", /exceeded the rate limit.*blocked with a 429/

      # Verify rate limit details are shown
      assert_select "section.rate-limit-section dt", "Limit Name"
      assert_select "section.rate-limit-section dd", "test_rate_limit"

      # Verify side panel shows rate limited indicator
      assert_select ".side-panel dt", /Rate Limited/
      assert_select ".side-panel dd", /Blocked.*429/
    end

    test "overview does not show rate limiting section for normal requests" do
      get success_scenarios_path
      request_id = request.request_id
      sleep 0.1

      get request_trace_path(id: request_id, tab: "overview")
      assert_response :success

      # Verify rate limiting section is NOT displayed
      assert_select "section.rate-limit-section", count: 0
      assert_select ".side-panel dt", text: /Rate Limited/, count: 0
    end
  end
end
