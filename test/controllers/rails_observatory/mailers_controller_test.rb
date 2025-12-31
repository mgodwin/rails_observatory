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

    test "index renders turbo frame for recent deliveries" do
      get mailers_path
      assert_response :success

      # Verify the turbo-frame element is present with lazy loading
      assert_select "turbo-frame#recent-deliveries[src='#{recent_mailers_path}'][loading='lazy']"
    end

    test "recent action renders deliveries" do
      get recent_mailers_path
      assert_response :success

      # Verify the turbo-frame wrapper is present
      assert_select "turbo-frame#recent-deliveries"
    end

    test "index renders summary panel" do
      get mailers_path
      assert_response :success

      assert_select "div.summary-panel" do
        assert_select "dt", text: "Emails Sent"
      end
    end

    test "index renders recent deliveries section" do
      get mailers_path
      assert_response :success

      assert_select "section.recent-requests" do
        assert_select "h2", text: "Recent Deliveries"
      end
    end
  end
end
