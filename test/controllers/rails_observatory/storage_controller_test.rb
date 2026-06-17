require "test_helper"

module RailsObservatory
  class StorageControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
      @test_keys.each { |key| @redis.call("DEL", "init:#{key}") }
    end

    test "index renders successfully with no data" do
      get storage_index_path
      assert_response :success
      assert_select "section.layout-requests_index-by_controller", count: 0
    end

    test "index renders summary panel" do
      get storage_index_path
      assert_response :success

      assert_select "div.summary-panel" do
        assert_select "dt", text: "Uploads"
        assert_select "dt", text: "Downloads"
        assert_select "dt", text: "Deletes"
        assert_select "dt", text: "Bytes Uploaded"
        assert_select "dt", text: "Avg Upload Duration"
      end
    end

    test "index renders charts" do
      get storage_index_path
      assert_response :success

      assert_select "#storage-upload-chart"
      assert_select "#storage-download-chart"
      assert_select "#storage-bytes-chart"
    end

    test "index renders service tables when data exists" do
      timestamp = Time.now

      2.times do
        RedisTimeSeries.increment("storage.upload_count", at: timestamp, labels: {service: "amazon"})
      end
      RedisTimeSeries.increment("storage.upload_count", at: timestamp, labels: {service: "local"})
      RedisTimeSeries.increment("storage.download_count", at: timestamp, labels: {service: "amazon"})
      RedisTimeSeries.increment("storage.delete_count", at: timestamp, labels: {service: "local"})
      RedisTimeSeries.distribution("storage.upload_bytes", 2048, at: timestamp, labels: {service: "amazon"})
      RedisTimeSeries.distribution("storage.upload_duration", 50.0, at: timestamp, labels: {service: "amazon"})

      track("storage.upload_count", {service: "amazon"}, %w[sum])
      track("storage.upload_count", {service: "local"}, %w[sum])
      track("storage.download_count", {service: "amazon"}, %w[sum])
      track("storage.delete_count", {service: "local"}, %w[sum])
      track("storage.upload_bytes", {service: "amazon"}, %w[avg min max std.p])
      track("storage.upload_duration", {service: "amazon"}, %w[avg min max std.p])

      get storage_index_path
      assert_response :success

      assert_select "section.layout-requests_index-by_controller h2", text: "Uploads by Service"
      assert_select "section.layout-requests_index-by_controller h2", text: "Downloads by Service"
      assert_select "section.layout-requests_index-by_controller h2", text: "Deletes by Service"
      assert_select "td", text: "amazon"
      assert_select "td", text: "local"
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
