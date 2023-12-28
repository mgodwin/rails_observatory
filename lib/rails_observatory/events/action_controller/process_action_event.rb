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

      def controller_action
        "#{controller.underscore}##{action}"
      end

      def labels
        { action: controller_action, format: request_format, status:, method: request_method }
      end

      def process
        record_metrics
      end

      def record_metrics
        RequestTimeSeries.distribution("latency", duration, labels:)
        RequestTimeSeries.distribution("latency/db_runtime", db_runtime, labels:)
        RequestTimeSeries.distribution("latency/view_runtime", view_runtime, labels:)
        RequestTimeSeries.increment("count", labels:)
        RequestTimeSeries.increment("error_count", labels:) if status >= 500
      end
    end
  end
end