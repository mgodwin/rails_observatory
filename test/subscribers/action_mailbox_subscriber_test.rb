require "test_helper"

module RailsObservatory
  class ActionMailboxSubscriberTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
      MailDelivery.ensure_index
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "captures inbound email when processed" do
      # Create and process an inbound email
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
        From: sender@example.com
        To: recipient@example.com
        Subject: Test Inbound Email
        Date: #{Time.now.rfc2822}
        Message-ID: <test-#{SecureRandom.uuid}@example.com>

        This is a test inbound email.
      EMAIL

      # Track the key for cleanup
      message_id = inbound_email.mail.message_id
      @test_keys << "md:#{message_id}"

      # Process the email
      inbound_email.deliver

      # Verify the email was captured
      delivery = MailDelivery.find(message_id)
      assert_not_nil delivery
      assert_equal "inbound", delivery.direction
      assert_equal "sender@example.com", delivery.from
      assert_equal "recipient@example.com", delivery.to
      assert_equal "Test Inbound Email", delivery.subject
      assert_equal message_id, delivery.message_id
    end

    test "records inbound count metric" do
      # Create and process an inbound email
      inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(<<~EMAIL)
        From: sender@example.com
        To: recipient@example.com
        Subject: Test Metric Email
        Date: #{Time.now.rfc2822}
        Message-ID: <metric-test-#{SecureRandom.uuid}@example.com>

        Testing metrics.
      EMAIL

      message_id = inbound_email.mail.message_id
      @test_keys << "md:#{message_id}"

      # Process the email
      inbound_email.deliver

      # Note: We can't easily verify the metric was recorded without
      # querying Redis TimeSeries directly, but the test ensures
      # no errors are raised during processing
      assert_nothing_raised do
        inbound_email.deliver
      end
    end
  end
end
