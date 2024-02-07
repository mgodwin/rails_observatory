module RailsObservatory
  class LogCollector < ::Logger

    KEY = :observatory_logs

    def initialize(*args, **kwargs)
      _, *rest = args
      super(nil, *rest, **kwargs)
    end

    def self.collect_logs
      logs = []
      ActiveSupport::IsolatedExecutionState[KEY] = logs
      yield
      logs
    ensure
      ActiveSupport::IsolatedExecutionState.delete(KEY)
    end

    def add(severity, message = nil, progname = nil, &block)
      if (logs = ActiveSupport::IsolatedExecutionState[KEY])
        severity ||= UNKNOWN
        return true if severity < level
        progname = @progname if progname.nil?
        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end
        logs << { severity:, message:, progname:, time: Time.now.to_f }
      end
    end

    alias log add

    def <<(message)
      if (logs = ActiveSupport::IsolatedExecutionState[KEY])
        logs << { severity: UNKNOWN, message:, progname: nil, time: Time.now.to_f }
      end
    end

  end
end