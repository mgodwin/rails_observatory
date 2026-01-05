require "test_helper"

module RailsObservatory
  class ErrorsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
      @created_fingerprints = []
      Error.ensure_index
    end

    def teardown
      # Clean up error records
      @created_fingerprints.each do |fp|
        @test_keys << Error.key_name(fp)
        Error.compressed_attributes.each do |attr|
          @test_keys << "error_#{attr}:#{fp}"
        end
      end
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "index renders successfully with no errors" do
      get errors_path
      assert_response :success
    end

    test "index renders error list when errors exist" do
      error = create_error("StandardError", "Something went wrong")
      @created_fingerprints << error.fingerprint

      get errors_path
      assert_response :success

      # Verify the error is displayed
      assert_select ".error" do
        assert_select "a", text: "StandardError"
      end
    end

    test "index renders error message" do
      error = create_error("RuntimeError", "Database connection failed")
      @created_fingerprints << error.fingerprint

      get errors_path
      assert_response :success

      assert_select "._message", text: "Database connection failed"
    end

    test "show renders error details" do
      error = create_error("ArgumentError", "Invalid parameter")
      @created_fingerprints << error.fingerprint

      # Create some error count time series data for the show page
      record_error_count(error.fingerprint)

      get error_path(error.fingerprint)
      assert_response :success
    end

    test "show raises not found for unknown fingerprint" do
      assert_raises(RedisModel::NotFound) do
        get error_path("nonexistent-fingerprint-abc123")
      end
    end

    private

    def create_error(class_name, message)
      exception = Object.const_get(class_name).new(message)
      exception.set_backtrace(caller)

      error = Error.new(
        exception: exception,
        location: "test#action",
        time: Time.now.to_f
      )
      error.save

      error
    end

    def record_error_count(fingerprint)
      base_time = Time.now
      labels = {fingerprint: fingerprint}

      # Track the time series keys for cleanup
      digest = Digest::SHA1.hexdigest(labels.sort.flatten.map(&:to_s).join).slice(0, 20)
      key = "error.count:#{digest}"
      @test_keys << key
      @test_keys << "#{key}_sum"
      @test_keys << "init:#{key}"

      RedisTimeSeries.increment("error.count", at: base_time.to_f, labels: labels)
    end
  end
end
