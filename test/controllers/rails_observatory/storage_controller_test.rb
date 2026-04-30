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
    end

    test "index renders successfully" do
      get storage_index_path
      assert_response :success
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
      service_name = "disk"
      timestamp = Time.now

      RedisTimeSeries.increment("storage.upload_count", at: timestamp, labels: {service: service_name})
      RedisTimeSeries.increment("storage.download_count", at: timestamp, labels: {service: service_name})
      RedisTimeSeries.increment("storage.delete_count", at: timestamp, labels: {service: service_name})

      digest = Digest::SHA1.hexdigest(["service", service_name].join).slice(0, 20)
      %w[storage.upload_count storage.download_count storage.delete_count].each do |metric|
        @test_keys += [
          "#{metric}:#{digest}",
          "#{metric}:#{digest}_sum",
          "init:#{metric}:#{digest}"
        ]
      end

      get storage_index_path
      assert_response :success

      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "Uploads by Service"
      end
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "Downloads by Service"
      end
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "Deletes by Service"
      end
    end
  end
end
