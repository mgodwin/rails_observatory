module RailsObservatory
  class RequestProcessor

    def self.handles?(event)
      event.type == name
    end
    def self.name
      "process_action.action_controller"
    end

    def process
      record_metrics
      Redis::IngestedRequestSet.new.add(self)
    end

    private

    def labels
      { action: controller_action, format: request_format, status:, method: request_method }
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