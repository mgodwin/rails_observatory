module RailsObservatory
  module Requests
    class ErrorCountMetric

      def self.name
        "requests.error_count"
      end

      def self.series
        RedisTimeSeries.where(name: name)
      end
    end

  end
end