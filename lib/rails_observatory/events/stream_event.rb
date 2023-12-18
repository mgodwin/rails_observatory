module RailsObservatory
  class StreamEvent
    attr_reader :id, :payload, :type, :duration

    def redis
      Rails.configuration.rails_observatory.redis
    end

    def initialize(payload:, type:, duration:, id:)
      @id = id
      @type = type
      @payload = payload
      @duration = duration.to_f
    end

    def timestamp
      Time.at(@id.split('-').first.to_i / 1000)
    end

    def rebroadcast_to(stream_name)
      redis.call('XADD', stream_name, id.split('-').first, 'name', name, 'payload', JSON.generate(payload), 'duration', duration)
    end

    def record_metrics
      # Override in subclass
    end

    def process
      # Override in subclass
    end

    def self.from_redis(redis_event)
      id, data = redis_event
      attributes = Hash[*data].deep_symbolize_keys
      attributes[:id] = id
      attributes[:payload] = JSON.parse(attributes[:payload]).deep_symbolize_keys
      class_name = ("rails_observatory/" + attributes[:type].split('.').reverse.join('/') + '_event').classify
      target_class = class_name.safe_constantize
      klass = self.subclasses.find { |klass| klass == target_class } || self
      klass.new(**attributes)
    end


  end
end