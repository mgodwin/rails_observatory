module RailsObservatory
  class ErrorSet
    include Enumerable

    def redis
      Rails.configuration.rails_observatory.redis
    end

    def initialize(name)
      @name = name
    end

    def each
      redis.call('ZRANGE', @name, 0, -1, 'REV', 'WITHSCORES').each do |fingerprint, score|
        yield JSON.parse(redis.call('GET', "errors:#{fingerprint}")).deep_symbolize_keys.merge(ts: score)
      end
    end
  end
end