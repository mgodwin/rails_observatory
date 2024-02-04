module RailsObservatory
  class EventSerializer
    def serialize(event)
        {
          name: event.name,
          payload: Serializer.serialize(event.payload),
          start_at: event.time,
          end_at: event.end,
          duration: event.duration,
          allocations: event.allocations,
          failed: event.payload.include?(:exception),
        }
    end

    def self.klass
      ActiveSupport::Notifications::Event
    end
  end
end