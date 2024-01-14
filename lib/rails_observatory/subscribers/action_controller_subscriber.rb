require_relative '../redis/time_series'
require_relative '../request'
require_relative '../redis/ingested_request_set'
module RailsObservatory
  class ActionControllerSubscriber < ActiveSupport::Subscriber
    attach_to :action_dispatch

    def request(event)
      # Skip requests for static assets and that don't route to a controller.
      return if event.payload[:request].controller_instance.nil?
      request = Request.create_from_event(event)
      IngestedRequestSet.new.add(request)

      labels = { action: request.action, format: request.format, status: request.status, method: request.http_method}

      TimeSeries.distribution("request.latency", request.duration, labels:)
      TimeSeries.distribution("request.latency/db_runtime", request.db_runtime, labels:)
      TimeSeries.distribution("request.latency/view_runtime", request.view_runtime, labels:)
      TimeSeries.increment("request.count", labels:)
      TimeSeries.increment("request.error_count", labels:) if request.status >= 500

      # Redis::RequestSet.new.add(event)
    end
  end
end