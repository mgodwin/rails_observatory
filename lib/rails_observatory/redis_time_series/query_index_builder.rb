module RailsObservatory
  class RedisTimeSeries
    class QueryIndexBuilder < QueryBuilder
      def initialize(name)
        super()
        @conditions = {name: name, compaction: true}
        @name = name
      end

      def where(**conditions)
        clone = self.clone
        clone.instance_variable_set(:@conditions, @conditions.merge(conditions))
        clone
      end

      def to_redis_args
        ["TS.QUERYINDEX", *redis_filters]
      end

      def to_redis_command
        to_redis_args.join(" ")
      end

      def each
        res = redis.call(to_redis_args)
        return if res.nil?

        res.each do |key|
          yield RedisTimeSeries.new(key)
        end
      end
    end
  end
end
