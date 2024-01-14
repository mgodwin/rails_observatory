module RailsObservatory
  class EventSerializer

    PERMITTED_TYPES = [NilClass, String, Integer, Float, TrueClass, FalseClass]

    class << self
      def serialize_event(event)
        {
          name: event.name,
          payload: serialize_payload(event.payload),
          start_at: event.time,
          end_at: event.end,
          duration: event.duration,
          allocations: event.allocations,
          failed: event.payload.include?(:exception),
        }
      end

      def serialize_payload(argument)
        case argument
        when *PERMITTED_TYPES
          argument
        when Array
          argument.map { serialize_payload(_1) }
        when ActiveSupport::HashWithIndifferentAccess
          serialize_hash(argument)
        when Hash
          serialize_hash(argument)
        when -> (arg) { arg.respond_to?(:permitted?) && arg.respond_to?(:to_h) }
          serialize_hash(argument.to_h)
        when Symbol
          argument.to_s
        else
          "Unable to serialize #{argument.class.name}"
          # raise "unknown argument type #{argument.class}"
          # Serializers.serialize(argument)
        end
      end

      def serialize_hash(argument)
        argument.each_with_object({}) do |(key, value), hash|
          case key
          when String, Symbol
            hash[key] = serialize_payload(value)
          end
        end
      end
    end
  end
end