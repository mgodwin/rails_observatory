module RailsObservatory
  class Request
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :request_id
    attribute :status, :integer
    attribute :http_method, :string
    attribute :path, :string
    attribute :time, :string
    attribute :rel_start, :float
    attribute :rel_end, :float
    attribute :duration, :float, default: 0
    attribute :action, :string
    attribute :format, :string
    attribute :db_runtime, :float, default: 0
    attribute :view_runtime, :float, default: 0
    attribute :rails_observatory_runtime, :float, default: 0
    attribute :allocations, :integer, default: 0
    #  :method, :format, :controller_action, :duration, :db_runtime, :view_runtime

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def self.create

    end

    def self.create_from_event(event)
      request = event.payload[:request]
      request_id = request.request_id
      route_pattern = request.route_uri_pattern
      http_method = request.request_method
      format = request.format.ref
      puts "request.controller_instance: #{request.controller_instance.inspect}"
      controller = request.controller_instance
      status = controller.response.status
      path = request.filtered_path

      controller_action = "#{controller.class.name}##{controller.action_name}"
      rel_start = event.time
      rel_end = event.end
      duration = event.duration

      new(action: controller_action,
          time: Time.now,
          request_id:, format:, http_method:, status:,
          rel_start:, rel_end:, duration:, path:).tap(&:save)
    end

    def self.find(request_id)
      attrs = redis.call("HGETALL", "request:#{request_id}").to_h
      puts "Found request:#{request_id} #{attrs.inspect}"
      self.new(attrs)
    end

    def self.ingested
      IngestedRequestSet.new.all
    end

    def start_at_time
      Time.at(start_at.to_f)
    end

    def end_at_time
      Time.at(end_at.to_f)
    end

    def events
      RequestEventSet.new(request_id).all
    end

    def save
      self.class.redis.call("HMSET", "request:#{request_id}", attributes)
    end
  end
end