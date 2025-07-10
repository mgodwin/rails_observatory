module RailsObservatory
  class EventCollector

    def self.capturing_events?
      ActiveSupport::IsolatedExecutionState[:rails_observatory_capture_events] == true
    end

    def self.current_events
      ActiveSupport::IsolatedExecutionState[:rails_observatory_events]
    end

    def self.start
      @subscriber ||= ActiveSupport::Notifications.subscribe(/\A[^!]/) do |event|
        current_events << event if capturing_events?
      end
    end

    def self.stop
      if @subscriber
        ActiveSupport::Notifications.unsubscribe(@subscriber)
        @subscriber = nil
      end
    end


    def self.collect_events
      raise "EventCollector must be started before collecting events" unless @subscriber
      events = []
      ActiveSupport::IsolatedExecutionState[:rails_observatory_capture_events] = true
      ActiveSupport::IsolatedExecutionState[:rails_observatory_events] = events
      yield
      events
    rescue Exception => e
      e.instance_variable_set(:@_trace_events, events)
      raise
    ensure
      ActiveSupport::IsolatedExecutionState.delete(:rails_observatory_capture_events)
      ActiveSupport::IsolatedExecutionState.delete(:rails_observatory_events)
    end
  end
end