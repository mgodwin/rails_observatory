module RailsObservatory
  class StreamEvent
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :id, :payload, :type, :duration, :start_at, :end_at

    attribute :failed, :boolean

    def redis
      Rails.configuration.rails_observatory.redis
    end

    def timestamp
      Time.at(@id.split('-').first.to_i / 1000)
    end

    def id_ts
      @id.split('-').first.to_i
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
      # class_name = ("rails_observatory/" + attributes[:type].split('.').reverse.join('/') + '_event').classify
      # target_class = class_name.safe_constantize
      # klass = self.subclasses.find { |klass| klass == target_class } || self
      new(**attributes)
    end


  end
end