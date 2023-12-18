module RailsObservatory
  class ErrorTimeSeries < RedisTimeSeries

    TS_KEY_PREFIX = "error"
    def self.where(fingerprint:)
      super(name: [TS_KEY_PREFIX, fingerprint].join(':'))
    end
  end
end