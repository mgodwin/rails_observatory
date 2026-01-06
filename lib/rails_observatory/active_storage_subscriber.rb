module RailsObservatory
  class ActiveStorageSubscriber < ActiveSupport::Subscriber
    attach_to :active_storage

    def service_upload(event)
      service = event.payload[:service]
      key = event.payload[:key]
      checksum = event.payload[:checksum]

      labels = {
        service: service
      }

      RedisTimeSeries.record_occurrence("storage.upload_count", at: event.time, labels: labels)
      RedisTimeSeries.record_timing("storage.upload_latency", event.duration, at: event.time, labels: labels)
    end

    def service_download(event)
      service = event.payload[:service]
      key = event.payload[:key]

      labels = {
        service: service
      }

      RedisTimeSeries.record_occurrence("storage.download_count", at: event.time, labels: labels)
      RedisTimeSeries.record_timing("storage.download_latency", event.duration, at: event.time, labels: labels)
    end

    def service_streaming_download(event)
      service = event.payload[:service]
      key = event.payload[:key]

      labels = {
        service: service
      }

      RedisTimeSeries.record_occurrence("storage.download_count", at: event.time, labels: labels)
      RedisTimeSeries.record_timing("storage.download_latency", event.duration, at: event.time, labels: labels)
    end

    def service_delete(event)
      service = event.payload[:service]
      key = event.payload[:key]

      labels = {
        service: service
      }

      RedisTimeSeries.record_occurrence("storage.delete_count", at: event.time, labels: labels)
    end
  end
end
