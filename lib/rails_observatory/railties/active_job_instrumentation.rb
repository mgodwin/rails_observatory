require_relative '../event_collector'
require_relative '../models/job_trace'
module RailsObservatory
  module Railties
    module ActiveJobInstrumentation

      def perform_now
        TimeSeries.distribution("job.queue_latency", Time.now - enqueued_at, labels: { queue_name: }) unless enqueued_at.nil?
        labels = { job_class: self.class.name, queue_name: }
        TimeSeries.increment("job.count", labels:)
        TimeSeries.increment("job.retry_count", labels:) if executions > 1

        start_at = Time.now
        start_at_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
        result = nil
        logs = []
        events = EventCollector.instance.collect_events do
          logs = LogCollector.collect_logs do
            result = super
          end
        end
        end_at_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
        result
      rescue Exception => error
        events = error.instance_variable_get(:@_trace_events)
        end_at_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
        TimeSeries.increment("job.error_count", labels:)
        raise
      ensure
        duration = end_at_mono - start_at_mono
        TimeSeries.distribution("job.latency", duration, labels:)
        JobTrace.new(
          job_id: job_id,
          time: start_at.to_f,
          duration:,
          queue_adapter: ActiveJob.adapter_name(queue_adapter),
          executions:,
          job_class: self.class.name,
          queue_name:,
          events: events.map { Serializer.serialize(_1) },
          logs:,
          error: error.present?
        ).save
      end

    end
  end
end
