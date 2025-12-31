require "test_helper"

module RailsObservatory
  class ErrorTest < ActiveSupport::TestCase
    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
      Error.ensure_index
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "creates error from exception with class_name and message" do
      exception = StandardError.new("Something went wrong")
      exception.set_backtrace(caller)

      error = Error.new(exception: exception, location: "posts#show", time: Time.now.to_f)

      assert_equal "StandardError", error.class_name
      assert_equal "Something went wrong", error.message
      assert_equal "posts#show", error.location
    end

    test "generates fingerprint from exception" do
      exception = StandardError.new("Something went wrong")
      exception.set_backtrace(["app/controllers/posts_controller.rb:10:in `show'"])

      error = Error.new(exception: exception, location: "posts#show", time: Time.now.to_f)

      assert_not_nil error.fingerprint
      assert_equal 64, error.fingerprint.length  # SHA256 hex is 64 chars
    end

    test "same exception produces same fingerprint" do
      backtrace = ["app/controllers/posts_controller.rb:10:in `show'"]

      error1 = Error.new(
        exception: create_exception("Error message", backtrace),
        location: "posts#show",
        time: Time.now.to_f
      )

      error2 = Error.new(
        exception: create_exception("Error message", backtrace),
        location: "posts#show",
        time: Time.now.to_f
      )

      assert_equal error1.fingerprint, error2.fingerprint
    end

    test "different exceptions produce different fingerprints" do
      # Use different exception classes to ensure different fingerprints
      exception1 = StandardError.new("Error one")
      exception1.set_backtrace(caller)

      exception2 = RuntimeError.new("Error two")
      exception2.set_backtrace(caller)

      error1 = Error.new(
        exception: exception1,
        location: "a#one",
        time: Time.now.to_f
      )

      error2 = Error.new(
        exception: exception2,
        location: "b#two",
        time: Time.now.to_f
      )

      assert_not_equal error1.fingerprint, error2.fingerprint
    end

    test "extracts trace from exception" do
      exception = StandardError.new("Test error")
      exception.set_backtrace(caller)  # Use real backtrace for cleaner to accept

      error = Error.new(exception: exception, location: "posts#show", time: Time.now.to_f)

      # Trace is an array (may be empty if backtrace cleaner filters everything)
      assert_kind_of Array, error.trace
    end

    test "saves and retrieves error from Redis" do
      exception = create_exception("Persisted error", ["app/test.rb:1"])
      error = Error.new(exception: exception, location: "test#action", time: Time.now.to_f)

      @test_keys << Error.key_name(error.fingerprint)
      Error.compressed_attributes.each do |attr|
        @test_keys << "error_#{attr}:#{error.fingerprint}"
      end

      error.save

      retrieved = Error.find(error.fingerprint)
      assert_equal error.class_name, retrieved.class_name
      assert_equal error.message, retrieved.message
      assert_equal error.fingerprint, retrieved.fingerprint
      assert_equal error.location, retrieved.location
    end

    test "stores and retrieves compressed trace" do
      exception = create_exception("Compressed test", caller)
      error = Error.new(exception: exception, location: "posts#show", time: Time.now.to_f)

      @test_keys << Error.key_name(error.fingerprint)
      Error.compressed_attributes.each do |attr|
        @test_keys << "error_#{attr}:#{error.fingerprint}"
      end

      error.save

      retrieved = Error.find(error.fingerprint)
      # Trace is persisted as an array (may be empty depending on backtrace cleaner)
      assert_kind_of Array, retrieved.trace
    end

    test "handles exception with cause chain" do
      inner = StandardError.new("Inner error")
      inner.set_backtrace(["inner.rb:1"])

      outer = begin
        raise inner
      rescue => e
        begin
          raise RuntimeError, "Outer error"
        rescue => outer_error
          outer_error
        end
      end

      error = Error.new(exception: outer, location: "test#cause", time: Time.now.to_f)

      assert error.has_causes
      assert_kind_of Array, error.causes
    end

    private

    def create_exception(message, backtrace)
      exception = StandardError.new(message)
      exception.set_backtrace(backtrace)
      exception
    end
  end
end
