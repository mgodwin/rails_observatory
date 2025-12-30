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

    test "index renders mailer tables when data exists" do
      # Insert test data for mailer.delivery_count with mailer label
      mailer = "TestMailer#welcome"
      timestamp = Time.now

      # Record a delivery count with mailer label
      RedisTimeSeries.increment("mailer.delivery_count", at: timestamp, labels: {mailer: mailer})

      # Track keys for cleanup
      count_digest = Digest::SHA1.hexdigest(["mailer", mailer].join).slice(0, 20)

      @test_keys += [
        "mailer.delivery_count:#{count_digest}",
        "mailer.delivery_count:#{count_digest}_sum",
        "init:mailer.delivery_count:#{count_digest}"
      ]

      get mailers_path
      assert_response :success

      # Verify the "By Mailer" section is rendered
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "By Mailer"
        assert_select "table" do
          assert_select "th", text: "Mailer"
          assert_select "th", text: "Emails"
        end
      end
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
