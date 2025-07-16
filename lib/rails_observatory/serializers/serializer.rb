module RailsObservatory
  class Serializer

    PERMITTED_TYPES = [NilClass, String, Integer, Float, TrueClass, FalseClass]

    ADDITIONAL_SERIALIZERS = [JobSerializer, MailDeliveryJobSerializer, EventSerializer, RequestSerializer, HeadersSerializer, ResponseSerializer]

    class << self


      def serialize(argument)
        serialize_payload(argument)
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
          ADDITIONAL_SERIALIZERS.find { argument.is_a?(_1.klass) }&.new&.serialize(argument)&.deep_stringify_keys || "Unable to serialize #{argument.class.name}"
        end
      end

      def serialize_hash(argument)
        argument.each_with_object({}) do |(key, value), hash|
          case key
          when String, Symbol
            hash[key.to_s] = serialize_payload(value)
          end
        end
      end
    end
  end
end