require "test_helper"

module RailsObservatory
  class JobsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "index renders successfully" do
      get jobs_path
      assert_response :success
    end

    test "index renders job tables when data exists" do
      # Insert test data for job.count with queue_name and job_class labels
      queue_name = "default"
      job_class = "TestJob"
      timestamp = Time.now

      # Record a job count with queue_name label
      RedisTimeSeries.increment("job.count", at: timestamp, labels: {queue_name: queue_name, job_class: job_class})

      # Record a latency timing with job_class label
      RedisTimeSeries.distribution("job.latency", 150.5, at: timestamp, labels: {job_class: job_class})

      # Track keys for cleanup
      count_digest = Digest::SHA1.hexdigest(["job_class", job_class, "queue_name", queue_name].join).slice(0, 20)
      latency_digest = Digest::SHA1.hexdigest(["job_class", job_class].join).slice(0, 20)

      @test_keys += [
        "job.count:#{count_digest}",
        "job.count:#{count_digest}_sum",
        "init:job.count:#{count_digest}",
        "job.latency:#{latency_digest}",
        "job.latency:#{latency_digest}_avg",
        "job.latency:#{latency_digest}_min",
        "job.latency:#{latency_digest}_max",
        "init:job.latency:#{latency_digest}"
      ]

      get jobs_path
      assert_response :success

      # Verify the "By Queue" section is rendered
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "By Queue"
        assert_select "table" do
          assert_select "th", text: "Queue"
          assert_select "th", text: "Jobs"
        end
      end

      # Verify the "By Job Class" section is rendered
      assert_select "section.layout-requests_index-by_controller" do
        assert_select "h2", text: "By Job Class"
        assert_select "table" do
          assert_select "th", text: "Job Class"
          assert_select "th", text: "Jobs"
          assert_select "th", text: "Avg Duration"
        end
      end
    end
  end
end
