require "test_helper"

module RailsObservatory
  class JobTracesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      @redis = Rails.configuration.rails_observatory.redis
      @test_keys = []
    end

    def teardown
      @test_keys.each { |key| @redis.call("DEL", key) }
    end

    test "show displays job trace overview" do
      # Perform a job to create a trace
      job = SuccessfulJob.perform_later(name: "Test Job")
      job_id = job.job_id

      # Process the job
      perform_enqueued_jobs

      sleep 0.1 # Wait for async worker

      # View the trace via job traces controller
      get job_trace_path(id: job_id, tab: "overview")
      assert_response :success

      # Verify job-specific details are shown in sidebar
      assert_select ".side-panel dt", text: "Duration"
      assert_select ".side-panel dt", text: "Queue Latency"
      assert_select "section h3", text: "Job Details"
      assert_select "section dl dt", text: "Job Class"
      assert_select "section dl dt", text: "Queue"
    end

    test "show displays job trace events tab" do
      job = SuccessfulJob.perform_later(name: "Test Job")
      job_id = job.job_id

      perform_enqueued_jobs
      sleep 0.1

      get job_trace_path(id: job_id, tab: "events")
      assert_response :success

      # Verify events tab content
      assert_select ".events-tab"
    end

    test "show displays job trace logs tab" do
      job = SuccessfulJob.perform_later(name: "Test Job")
      job_id = job.job_id

      perform_enqueued_jobs
      sleep 0.1

      get job_trace_path(id: job_id, tab: "logs")
      assert_response :success

      # Verify logs tab content
      assert_select ".logs"
    end

    test "recent returns job traces" do
      # Perform a job to create a trace
      SuccessfulJob.perform_later(name: "Recent Test Job")
      perform_enqueued_jobs
      sleep 0.1

      get recent_job_traces_path
      assert_response :success

      # Verify turbo frame and table structure
      assert_select "turbo-frame#recent-traces"
    end
  end
end
