module RailsObservatory
  class EventStream


    class Event
      attr_reader :id
      def initialize(redis_event)
        @id = redis_event[0]
        @event = Hash[*redis_event[1]]
      end

      def timestamp
        Time.at(@id.split('-').first.to_i / 1000)
      end

      def name
        @event['event']
      end

      def duration
        @event['duration'].to_f
      end

      def payload
        @payload ||= JSON.parse(@event['payload'])
      end

    end

    def self.from(stream_name)
      new(stream_name)
    end

    def initialize(stream)
      @stream = stream
    end
    def events(&blk)
      return enum_for(:events) unless block_given?
      id = "+"
      loop do
        raw_events = $redis.call("XREVRANGE", @stream, id, "-", "COUNT", "1000")
        break if raw_events.empty?
        events = raw_events.map { |e| Event.new(e) }.each(&blk)
        id = "(#{events.last.id}"
      end
    end
  end
end