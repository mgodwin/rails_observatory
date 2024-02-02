require_relative './redis_model'
module RailsObservatory
  class RequestTrace < RedisModel

    attribute :request_id, :string
    attribute :status, :integer
    attribute :http_method, :string
    attribute :path, :string
    attribute :action, :string
    attribute :format, :string
    attribute :error, :boolean
    attribute :route_pattern, :string
    attribute :time, :float
    attribute :duration, :float
    attribute :allocations, :integer, indexed: false

    alias_attribute :id, :request_id
    alias_attribute :name, :action

    # after_event_added "process_action.action_controller" do |event|
    #   self.request_id = event.payload[:request].request_id
    #   self.status = event.payload[:status]
    #   self.http_method = event.payload[:method]
    #   self.path = event.payload[:path]
    #   self.action = "#{event.payload[:controller]}##{event.payload[:action]}"
    #   self.format = event.payload[:format]
    #   self.error = event.payload[:exception]
    # end

    # after_event_added "request.action_dispatch" do |event|
    #   self.route_pattern = event.payload[:request].route_uri_pattern || ''
    #   self.time = Time.now.to_f
    #   self.duration = event.duration
    #   self.allocations = event.allocations
    #
    #   save
    #
    #   labels = { action:, format:, status:, http_method: }
    #   TimeSeries.increment("request.count", labels:)
    #   TimeSeries.increment("request.error_count", labels:) if status >= 500
    #   TimeSeries.distribution("request.latency", duration, labels:)
    # end
  end
end