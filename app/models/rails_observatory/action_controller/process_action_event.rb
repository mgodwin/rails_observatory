module RailsObservatory
  module ActionController
    class ProcessActionEvent < StreamEvent

      def db_runtime
        payload[:db_runtime] || 0
      end

      def view_runtime
        payload[:view_runtime] || 0
      end

      def status
        payload[:status]
      end

      def controller
        payload[:controller]
      end

      def action
        payload[:action]
      end

      def request_format
        payload[:format]
      end

      def request_method
        payload[:method]
      end

      def labels
        { action: "#{controller.underscore}##{action}", format: request_format, status:, method: request_method }
      end

      def record_metrics
        TimeSeries.distribution("request.latency", duration, labels:)
        TimeSeries.distribution("request.latency/db_runtime", db_runtime, labels:)
        TimeSeries.distribution("request.latency/view_runtime", view_runtime, labels:)
        TimeSeries.increment("request.count", labels:)
        TimeSeries.increment("request.error_count", labels:) if status >= 500
      end
    end
  end
end