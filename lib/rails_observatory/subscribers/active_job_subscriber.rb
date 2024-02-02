require_relative '../redis/time_series'
require_relative '../request'
require_relative '../redis/ingested_request_set'
module RailsObservatory
  class ActiveJobSubscriber < ActiveSupport::Subscriber
    attach_to :active_job
    def perform(event)
      # Skip requests for static assets and that don't route to a controller.
      job = Job.create_from_event(event)

      labels = { action: request.action, format: request.format, status: request.status, method: request.http_method}

      TimeSeries.increment("job.count", labels: )
      TimeSeries.increment("job.error_count", labels: ) if failed?
      TimeSeries.increment("job.retry_count", labels: ) if executions > 1
      TimeSeries.distribution("job.queue_latency", queue_duration, labels: { queue_name: queue_name }) if queue_duration
      TimeSeries.distribution("job.latency", duration, labels: )



    end


  end
end