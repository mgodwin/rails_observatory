module RailsObservatory
  module ActiveJob
    class PerformEvent < StreamEvent

      def queue_name
        payload[:queue_name]
      end

      def job_class
        payload[:job_class]
      end

      def failed?
        payload[:failed]
      end

      def executions
        payload[:executions].to_i
      end

      def labels
        { queue_name: , job_class: }
      end

      def process
        JobTimeSeries.increment("count", **labels)
        JobTimeSeries.increment("error_count", **labels) if failed?
        JobTimeSeries.increment("retry_count", **labels) if executions > 1
        JobTimeSeries.distribution("job.latency", duration, **labels)
      end
    end
  end
end