module RailsObservatory
  class RedisTimeSeries
    class QueryBuilder
      include RedisConnection
      include Enumerable

      protected

      def redis_filters
        @conditions.map do |k, v|
          case v
          when true
            "#{k}!="
          when false
            "#{k}="
          when Array
            "#{k}=(#{v.join(",")})"
          else
            "#{k}=#{v}"
          end
        end.to_a
      end
    end
  end
end
