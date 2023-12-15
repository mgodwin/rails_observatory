module RailsObservatory
  module RedisTimeSeries::Querying
      def where(**conditions)

        keys = $redis.call("TS.QUERYINDEX", *conditions.map do |k, v|
          if v == "*"
            "#{k}!="
          else
            "#{k}=#{v}"
          end
        end.to_a)

        keys.map { |key| self.new(key) }
      end
  end
end