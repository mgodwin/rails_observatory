module RailsObservatory
  class ErrorTimeSeries < RedisTimeSeries

    PREFIX = "error"

    def fingerprint
      labels[:name].split('.').last
    end

    def self.where(fingerprint:)
      puts "fingerprint: #{fingerprint}"
      super(name: fingerprint)
    end

    def self.increment(fingerprint)
      super(fingerprint)
    end
  end
end