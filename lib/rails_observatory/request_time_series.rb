module RailsObservatory
  class RequestTimeSeries < RedisTimeSeries

    PREFIX = "request"
    def self.where(name: nil, action: nil, method: nil, format: nil, status: nil, parent: nil)
      super(name: name, action:, method:, format:, status:, parent:)
    end
  end
end