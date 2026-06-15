require "test_helper"

module RailsObservatory
  class MailersControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "index renders successfully" do
      get mailers_path
      assert_response :success
    end

    test "index renders turbo frames for outbound and inbound deliveries" do
      get mailers_path
      assert_response :success

      # Verify the outbound turbo-frame element is present with lazy loading
      assert_select "turbo-frame#recent-outbound-deliveries[src='#{recent_mailers_path(direction: 'outbound')}'][loading='lazy']"

      # Verify the inbound turbo-frame element is present with lazy loading
      assert_select "turbo-frame#recent-inbound-deliveries[src='#{recent_mailers_path(direction: 'inbound')}'][loading='lazy']"
    end

    test "recent action renders outbound deliveries" do
      get recent_mailers_path(direction: "outbound")
      assert_response :success

      # Verify the turbo-frame wrapper is present
      assert_select "turbo-frame#recent-outbound-deliveries"
    end

    test "recent action renders inbound deliveries" do
      get recent_mailers_path(direction: "inbound")
      assert_response :success

      # Verify the turbo-frame wrapper is present
      assert_select "turbo-frame#recent-inbound-deliveries"
    end

    test "index renders summary panel with sent and received counts" do
      get mailers_path
      assert_response :success

      assert_select "div.summary-panel" do
        assert_select "dt", text: "Emails Sent"
        assert_select "dt", text: "Emails Received"
      end
    end

    test "index renders outbound deliveries section" do
      get mailers_path
      assert_response :success

      assert_select "section.recent-requests" do
        assert_select "h2", text: "Outbound Deliveries"
      end
    end

    test "index renders inbound deliveries section" do
      get mailers_path
      assert_response :success

      assert_select "section.recent-requests" do
        assert_select "h2", text: "Inbound Deliveries"
      end
    end
  end
end
