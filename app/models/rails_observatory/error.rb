module RailsObservatory
  class Error

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def self.find(fingerprint)
      attributes = JSON.parse(redis.call('GET', "errors:#{fingerprint}")).deep_symbolize_keys
      new(**attributes)
    end

    attr_accessor :fingerprint, :class_name, :message, :backtrace, :request_id
    def initialize(fingerprint:, class_name:, message:, backtrace:, request_id:)
      @fingerprint = fingerprint
      @class_name = class_name
      @message = message
      @backtrace = backtrace
      @request_id = request_id
    end

  end
end