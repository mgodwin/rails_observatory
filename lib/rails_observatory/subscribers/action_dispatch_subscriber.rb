require_relative '../redis/time_series'
module RailsObservatory
  class ActionDispatchSubscriber < ActiveSupport::Subscriber
    attach_to :action_dispatch

    def request(event)
      # Skip requests for static assets and that don't route to a controller.
      return if event.payload[:request].controller_instance.nil?

      request = event.payload[:request]
      http_method = request.request_method
      format = request.format.ref
      controller = request.controller_instance
      controller_action = "#{controller.class.name}##{controller.action_name}"
      status = request.get_header('rails_observatory.exception_status') || controller.response.status || request.status

      labels = { action: controller_action, format:, status:, method: http_method }

      TimeSeries.distribution("request.latency", event.duration, labels:)
      TimeSeries.increment("request.count", labels:)
      TimeSeries.increment("request.error_count", labels:) if status >= 500
    end
  end
end