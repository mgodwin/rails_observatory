module RailsObservatory
  class ControllerSubscriber < ActiveSupport::Subscriber
    attach_to :action_controller

    def process_action(event)
      { db_runtime: nil, **event.payload } => { controller:, action:, format:, status:, method:, db_runtime:, view_runtime: }
      labels = { action: "#{controller.underscore}##{action}", format:, status:, method: }
      $redis.with do |r|
        if r.call("HEXISTS", "controller_to_ids", labels[:action]) == 0
          id = SecureRandom.alphanumeric(8)
          r.call("HSET", "controller_to_ids", labels[:action], id)
          r.call("HSET", "ids_to_controller", id, labels[:action])
        end
      end

      TimeSeries.timing("#{event.name}.latency", event.duration, labels: labels)
      TimeSeries.timing("#{event.name}.latency/db_runtime", db_runtime || 0, labels: labels)
      TimeSeries.timing("#{event.name}.latency/view_runtime", view_runtime || 0, labels: labels)
      TimeSeries.increment("#{event.name}.count", labels: labels)
      if status >= 500
        TimeSeries.increment("#{event.name}.count/errors", labels: labels)
      end
    end
  end
end