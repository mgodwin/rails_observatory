module RailsObservatory
  class LogTimeSeries < Redis::TimeSeries

    PREFIX = "log"
    def self.where(name: nil, level: nil)
      super(name:, level:)
    end
  end
end