module RailsObservatory
  class EventStreamLogger < ::Logger

    def initialize(*args, **kwargs)
      _, *rest = args
      super(nil, *rest, **kwargs)
    end

    def build_payload(progname, &block)
      context = ActiveSupport::ExecutionContext.to_h
      payload = {}
      payload[:request_id] = context[:controller]&.request&.request_id || context[:job]&.request_id
      payload[:job_id] = context[:job]&.job_id
      payload[:message] = progname || block.call
      payload
    end

    def debug(progname = nil, &block)
      LogsStream.add_to_stream(type: "debug.log", payload: build_payload(progname, &block), duration: 0)
    end

    def info(progname = nil, &block)
      LogsStream.add_to_stream(type: "info.log", payload: build_payload(progname, &block), duration: 0)
    end

    def warn(progname = nil, &block)
      LogsStream.add_to_stream(type: "warn.log", payload: build_payload(progname, &block), duration: 0)
    end

    def error(progname = nil, &block)
      LogsStream.add_to_stream(type: "error.log", payload: build_payload(progname, &block), duration: 0)
    end

    def fatal(progname = nil, &block)
      LogsStream.add_to_stream(type: "fatal.log", payload: build_payload(progname, &block), duration: 0)
    end

    def unknown(progname = nil, &block)
      LogsStream.add_to_stream(type: "unknown.log", payload: build_payload(progname, &block), duration: 0)
    end

    def add(severity, message = nil, progname = nil, &block)
      if severity >= level
        LogsStream.add_to_stream(type: "#{severity}.log", payload: build_payload(message, &block), duration: 0)
      end
    end
    alias log add

    def <<(message)
      LogsStream.add_to_stream(type: "unknown.log", payload: build_payload(message, &block), duration: 0)
    end

  end
end