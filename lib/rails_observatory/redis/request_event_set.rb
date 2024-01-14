require_relative './sorted_set'
require_relative '../serializers/serializer'

module RailsObservatory
  class RequestEventSet < SortedSet

    def initialize(request_id)
      @name = "request:#{request_id}:events"
    end

    def add(event)
      serialized_event = EventSerializer.serialize_event(event)
      super(serialized_event, event.time)
    end

    def all
      LimitOffsetEnumerator.new(self) do |serialized_event|
        JSON.parse(serialized_event)
      end
    end

  end
end