module RailsObservatory
  module Requests
    class LatencyMetric

      def self.name
        "requests.latency"
      end

      def self.series
        RedisTimeSeries.where(name: name)
      end
    end

  end
end