module RailsObservatory
  class RequestTimeSeries < RedisTimeSeries

    TS_KEY_PREFIX = "request"
    def self.where(type: nil, action: nil, method: nil, format: nil, status: nil, parent: nil)
      super(name: [TS_KEY_PREFIX, type].join('.'), action:, method:, format:, status:, parent:)
    end
  end
end