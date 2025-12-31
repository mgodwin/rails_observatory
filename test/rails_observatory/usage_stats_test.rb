require "test_helper"

module RailsObservatory
  class UsageStatsTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
      MailDelivery.ensure_index
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "mail patterns match MailDelivery key prefix" do
      mail_patterns = UsageStats::CATEGORIES[:mail][:patterns]
      expected_prefix = MailDelivery.key_prefix

      # Main document pattern should match key_prefix:*
      assert_includes mail_patterns, "#{expected_prefix}:*",
        "Expected mail patterns to include '#{expected_prefix}:*' but got #{mail_patterns.inspect}"

      # Compressed attribute pattern should match key_prefix_mail:*
      assert_includes mail_patterns, "#{expected_prefix}_mail:*",
        "Expected mail patterns to include '#{expected_prefix}_mail:*' but got #{mail_patterns.inspect}"
    end

    test "error patterns match Error key prefix" do
      error_patterns = UsageStats::CATEGORIES[:errors][:patterns]
      expected_prefix = Error.key_prefix

      assert_includes error_patterns, "#{expected_prefix}:*",
        "Expected error patterns to include '#{expected_prefix}:*'"

      # Check compressed attribute patterns
      Error.compressed_attributes.each do |attr|
        expected_pattern = "#{expected_prefix}_#{attr}:*"
        assert_includes error_patterns, expected_pattern,
          "Expected error patterns to include '#{expected_pattern}'"
      end
    end

    test "trace patterns match RequestTrace and JobTrace key prefixes" do
      trace_patterns = UsageStats::CATEGORIES[:traces][:patterns]

      assert_includes trace_patterns, "#{RequestTrace.key_prefix}:*",
        "Expected trace patterns to include RequestTrace prefix"
      assert_includes trace_patterns, "#{JobTrace.key_prefix}:*",
        "Expected trace patterns to include JobTrace prefix"
    end

    test "mail category stats reflect stored mail deliveries" do
      mail = MailDelivery.new(
        message_id: "test-mail-#{SecureRandom.hex(8)}",
        time: Time.now.to_f,
        duration: 0.1,
        mailer: "TestMailer",
        to: "test@example.com",
        from: "sender@example.com",
        subject: "Test Subject",
        mail: {body: "Test body"}
      )

      @test_keys << MailDelivery.key_name(mail.message_id)
      @test_keys << "#{MailDelivery.key_prefix}_mail:#{mail.message_id}"

      mail.save

      stats = UsageStats.new
      mail_stats = stats.category_stats[:mail]

      assert mail_stats[:key_count] >= 2,
        "Expected at least 2 mail keys (document + compressed attribute), got #{mail_stats[:key_count]}"
      assert mail_stats[:bytes] > 0,
        "Expected mail bytes > 0, got #{mail_stats[:bytes]}"
    end
  end
end
