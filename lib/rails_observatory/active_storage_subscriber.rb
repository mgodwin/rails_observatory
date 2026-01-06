module RailsObservatory
  class ActiveStorageSubscriber < ActiveSupport::Subscriber
    attach_to :active_storage

    def service_upload(event)
      event.payload => {key:, service:, checksum:}
      bytesize = event.payload[:bytesize] || 0
      service_name = service.is_a?(String) ? service : service.class.name.demodulize.underscore

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.upload_count", labels:)
      RedisTimeSeries.record_timing("storage.upload_bytes", bytesize, labels:)
      RedisTimeSeries.record_timing("storage.upload_duration", event.duration, labels:)
    end

    def service_download(event)
      event.payload => {key:, service:}
      service_name = service.is_a?(String) ? service : service.class.name.demodulize.underscore

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.download_count", labels:)
    end

    def service_streaming_download(event)
      event.payload => {key:, service:}
      service_name = service.is_a?(String) ? service : service.class.name.demodulize.underscore

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.download_count", labels:)
    end

    def service_delete(event)
      event.payload => {key:, service:}
      service_name = service.is_a?(String) ? service : service.class.name.demodulize.underscore

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.delete_count", labels:)
    end

    def preview(event)
      event.payload => {key:}
      service_name = extract_service_name(event)

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.preview_count", labels:)
      RedisTimeSeries.record_timing("storage.preview_duration", event.duration, labels:)
    end

    def transform(event)
      event.payload => {key:}
      service_name = extract_service_name(event)

      labels = {service: service_name}
      RedisTimeSeries.record_occurrence("storage.transform_count", labels:)
      RedisTimeSeries.record_timing("storage.transform_duration", event.duration, labels:)
    end

    def analyze(event)
      event.payload => {analyzer:}
      service_name = extract_service_name(event)
      analyzer_name = analyzer.is_a?(String) ? analyzer : analyzer.class.name.demodulize.underscore

      labels = {service: service_name, analyzer: analyzer_name}
      RedisTimeSeries.record_occurrence("storage.analyze_count", labels:)
      RedisTimeSeries.record_timing("storage.analyze_duration", event.duration, labels:)
    end

    private

    def extract_service_name(event)
      service = event.payload[:service]
      return "unknown" unless service
      service.is_a?(String) ? service : service.class.name.demodulize.underscore
    end
  end
end
