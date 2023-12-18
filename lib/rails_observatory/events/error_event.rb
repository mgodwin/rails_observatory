module RailsObservatory
  class ErrorEvent < StreamEvent

    def process
      redis.multi do |r|
        r.call('ZADD', 'errors_by_recency', id.split('-').first, payload[:fingerprint])
        r.call('ZINCRBY', 'errors_by_total_count', 1, payload[:fingerprint])
        r.call('SET', "errors:#{payload[:fingerprint]}", JSON.generate(payload))
      end
    end

  end
end