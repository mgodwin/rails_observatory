module RailsObservatory
  class ErrorsStream < RedisStream

    def self.add_to_stream(exception, **payload)
      backtrace = Rails.backtrace_cleaner.clean(exception&.backtrace).presence || exception&.backtrace
      payload[:class_name] = exception.class.name
      payload[:message] = exception.message
      payload[:backtrace] = backtrace
      payload[:fingerprint] = Digest::MD5.hexdigest(exception.class.name + backtrace.join("\n"))
      super(type: 'error', payload: payload, duration: 0)
    end
  end
end