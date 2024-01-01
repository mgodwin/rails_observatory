module RailsObservatory
  class EventStreamLogger < ::Logger

    def initialize(*args, **kwargs)
      _, *rest = args
      super(nil, *rest, **kwargs)
    end

    def build_payload(level, message, progname, &block)
      context = ActiveSupport::ExecutionContext.to_h
      payload = {}
      payload[:level] = level
      payload[:request_id] = context[:controller]&.request&.request_id || context[:job]&.request_id
      payload[:job_id] = context[:job]&.job_id
      payload[:message] = message
      payload[:message] ||= block_given? ? block.call : progname
      payload
    end

    def add(severity, message = nil, progname = nil, &block)
      if severity >= level
        LogsStream.add_to_stream(type: "log", payload: build_payload(format_severity(severity), message, progname, &block), duration: 0)
      end
    end

    alias log add

    private

    def format_severity(severity)
      super
    end

    def <<(message)
      LogsStream.add_to_stream(type: "log", payload: build_payload('unknown', message, &block), duration: 0)
    end

  end
end