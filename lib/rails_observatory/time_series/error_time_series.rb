module RailsObservatory
  class ErrorTimeSeries < Redis::TimeSeries

    PREFIX = "error"

    def fingerprint
      labels[:name].split('.').last
    end

    def self.where(fingerprint:)
      super(name: fingerprint)
    end

    def self.increment(fingerprint)
      super(fingerprint)
    end
  end
end