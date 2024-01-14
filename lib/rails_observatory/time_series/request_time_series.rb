require_relative '../redis/time_series'
module RailsObservatory
  class RequestTimeSeries < Redis::TimeSeries

    PREFIX = "request"
    def self.where(name: nil, action: nil, method: nil, format: nil, status: nil, parent: nil)
      super(name: name, action:, method:, format:, status:, parent:)
    end
  end
end