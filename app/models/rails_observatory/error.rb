module RailsObservatory
  class Error

    include ActiveModel::Model

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def self.find(fingerprint)
      attributes = JSON.parse(redis.call('GET', "errors:#{fingerprint}")).deep_symbolize_keys
      new(**attributes)
    end

    attr_accessor :fingerprint, :class_name, :message, :trace, :request_id, :latest_ts, :source_extracts, :location, :has_causes, :causes

    def count
      @count ||= self.class.redis.call('ZSCAN', 'errors_by_total_count', 0, 'MATCH', fingerprint, 'COUNT', 1).dig(1, 1)
    end

    def last_seen

      @last_seen ||= begin
                       res = self.class.redis.call('ZSCAN', 'errors_by_recency', 0, 'MATCH', fingerprint, 'COUNT', 1).dig(1, 1)
                       Time.at(res.to_i / 1000)
                     end
    end

  end
end