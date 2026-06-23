module RailsObservatory
  class RequestTrace < RedisModel
    include Events
    include Logs

    attribute :request_id, :string
    attribute :status, :integer
    attribute :http_method, :string
    attribute :path, :string
    attribute :action, :string
    attribute :format, :string
    attribute :request_type, :string
    attribute :error, :boolean
    attribute :route_pattern, :string
    attribute :time, :float
    attribute :duration, :float
    attribute :allocations, :integer, indexed: false

    alias_attribute :id, :request_id
    alias_attribute :name, :action

    after_save :record_metrics

    def self.key_prefix
      "rt"
    end

    def self.create_from_request(request, start_at, duration, status, events:, logs:)
      serialized_events = events.map { |event| Serializer.serialize(event) }
      controller_action = "#{request.params[:controller]}##{request.params[:action]}"
      new(
        request_id: request.request_id,
        status:,
        http_method: request.method,
        route_pattern: request.route_uri_pattern,
        action: controller_action,
        error: events.any? { it.payload[:exception] },
        format: request.format,
        request_type: detect_request_type(request),
        duration:,
        time: start_at.to_f,
        path: request.path,
        events: serialized_events,
        logs:
      )
    end

    def self.detect_request_type(request)
      accept = request.headers["Accept"] || ""
      if accept.include?("text/vnd.turbo-stream.html")
        "turbo_stream"
      elsif request.headers["Turbo-Frame"].present?
        "turbo_frame"
      elsif request.xhr?
        "xhr"
      else
        "page"
      end
    end

    private

    def record_metrics
      labels = {action:, format:, status:, http_method:}
      RedisTimeSeries.record_occurrence("request.count", at: time, labels:)
      RedisTimeSeries.record_occurrence("request.error_count", at: time, labels:) if status >= 500
      RedisTimeSeries.record_timing("request.latency", duration, at: time, labels:)

      # Record per-library latency breakdown for namespace chart
      events.self_time_by_library.each do |library, self_time|
        RedisTimeSeries.record_timing("request.latency", self_time, at: time, labels: {action:, namespace: library})
      end
    end
  end
end
