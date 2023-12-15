module RailsObservatory
  module Requests
    class CountMetric

      def self.name
        "requests.count"
      end

      def self.series
        RedisTimeSeries.where(name: name)
      end
    end

  end
end