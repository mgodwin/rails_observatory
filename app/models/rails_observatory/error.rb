module RailsObservatory
  class Error

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def self.find(fingerprint)
      attributes = JSON.parse(redis.call('GET', "errors:#{fingerprint}")).deep_symbolize_keys
      new(**attributes)
    end

    attr_accessor :fingerprint, :class_name, :message, :backtrace, :request_id, :latest_ts
    def initialize(fingerprint:, class_name:, message:, backtrace:, request_id:, latest_ts: nil)
      @fingerprint = fingerprint
      @class_name = class_name
      @message = message
      @backtrace = backtrace
      @request_id = request_id
      @latest_ts = latest_ts
    end

    def count
      @count ||= self.class.redis.call('ZSCAN', 'errors_by_total_count', 0, 'MATCH', fingerprint, 'COUNT', 1).dig(1,1)
    end

  end
end