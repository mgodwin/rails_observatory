require "test_helper"

module RailsObservatory
  class ActiveStorageSubscriberTest < ActiveSupport::TestCase
    class FakeS3Service
    end

    class FakeImageAnalyzer
    end

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
      @test_keys.each { |key| @redis.call("DEL", "init:#{key}") }
    end

    test "service_upload records count, bytes, and duration with service label" do
      ts_count = track("storage.upload_count", {service: "amazon"}, %w[sum])
      ts_bytes = track("storage.upload_bytes", {service: "amazon"}, %w[avg min max std.p])
      ts_duration = track("storage.upload_duration", {service: "amazon"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "service_upload.active_storage",
        key: "abc123", service: "amazon", checksum: "xyz", bytesize: 1024
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("EXISTS", ts_bytes)
      assert_equal 1, @redis.call("EXISTS", ts_duration)
      assert_equal 1024, @redis.call("TS.GET", ts_bytes)[1].to_i
    end

    test "service_upload derives service name from service object class" do
      ts_count = track("storage.upload_count", {service: "fake_s3_service"}, %w[sum])
      track("storage.upload_bytes", {service: "fake_s3_service"}, %w[avg min max std.p])
      track("storage.upload_duration", {service: "fake_s3_service"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "service_upload.active_storage",
        key: "abc", service: FakeS3Service.new, checksum: "xyz", bytesize: 512
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
    end

    test "service_upload defaults bytesize to 0 when missing from payload" do
      ts_bytes = track("storage.upload_bytes", {service: "amazon"}, %w[avg min max std.p])
      track("storage.upload_count", {service: "amazon"}, %w[sum])
      track("storage.upload_duration", {service: "amazon"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "service_upload.active_storage",
        key: "abc", service: "amazon", checksum: "xyz"
      ) { sleep 0.001 }

      assert_equal 0, @redis.call("TS.GET", ts_bytes)[1].to_i
    end

    test "service_download records download count" do
      ts_count = track("storage.download_count", {service: "amazon"}, %w[sum])

      ActiveSupport::Notifications.instrument(
        "service_download.active_storage",
        key: "abc", service: "amazon"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("TS.GET", ts_count)[1].to_i
    end

    test "service_streaming_download records download count" do
      ts_count = track("storage.download_count", {service: "amazon"}, %w[sum])

      ActiveSupport::Notifications.instrument(
        "service_streaming_download.active_storage",
        key: "abc", service: "amazon"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("TS.GET", ts_count)[1].to_i
    end

    test "service_delete records delete count" do
      ts_count = track("storage.delete_count", {service: "local"}, %w[sum])

      ActiveSupport::Notifications.instrument(
        "service_delete.active_storage",
        key: "abc", service: "local"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("TS.GET", ts_count)[1].to_i
    end

    test "preview records count and duration" do
      ts_count = track("storage.preview_count", {service: "amazon"}, %w[sum])
      ts_duration = track("storage.preview_duration", {service: "amazon"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "preview.active_storage",
        key: "abc", service: "amazon"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("EXISTS", ts_duration)
    end

    test "transform records count and duration" do
      ts_count = track("storage.transform_count", {service: "amazon"}, %w[sum])
      ts_duration = track("storage.transform_duration", {service: "amazon"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "transform.active_storage",
        key: "abc", service: "amazon"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("EXISTS", ts_duration)
    end

    test "analyze records count and duration with service and analyzer labels" do
      labels = {analyzer: "image_analyzer", service: "amazon"}
      ts_count = track("storage.analyze_count", labels, %w[sum])
      ts_duration = track("storage.analyze_duration", labels, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "analyze.active_storage",
        key: "abc", service: "amazon", analyzer: "image_analyzer"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
      assert_equal 1, @redis.call("EXISTS", ts_duration)
    end

    test "analyze derives analyzer name from analyzer object class" do
      labels = {analyzer: "fake_image_analyzer", service: "amazon"}
      ts_count = track("storage.analyze_count", labels, %w[sum])
      track("storage.analyze_duration", labels, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "analyze.active_storage",
        key: "abc", service: "amazon", analyzer: FakeImageAnalyzer.new
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
    end

    test "preview labels service as unknown when payload has no service" do
      ts_count = track("storage.preview_count", {service: "unknown"}, %w[sum])
      track("storage.preview_duration", {service: "unknown"}, %w[avg min max std.p])

      ActiveSupport::Notifications.instrument(
        "preview.active_storage",
        key: "abc"
      ) { sleep 0.001 }

      assert_equal 1, @redis.call("EXISTS", ts_count)
    end

    private

    def digest_for(labels)
      Digest::SHA1.hexdigest(labels.sort.flatten.map(&:to_s).join).slice(0, 20)
    end

    def track(name, labels, compactions)
      ts = "#{name}:#{digest_for(labels)}"
      @test_keys << ts
      compactions.each { |c| @test_keys << "#{ts}_#{c}" }
      ts
    end
  end
end
