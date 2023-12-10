module RailsObservatory
  class EventStream


    class Event
      def initialize(redis_event)
        @id = redis_event[0]
        @event = Hash[*redis_event[1]]
      end

      def timestamp
        Time.at(@event['ts'].to_i / 1000)
      end

      def name
        @event['name']
      end

      def duration
        @event['duration'].to_f
      end

    end

    def initialize(stream)
      @stream = stream
    end
    def events
      events = $redis.call("XREVRANGE", @stream, "+", "-", "COUNT", "1000")
      events.map { |e| Event.new(e) }
    end
  end
end