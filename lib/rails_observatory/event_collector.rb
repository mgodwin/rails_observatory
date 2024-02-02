module RailsObservatory
  class EventCollector
    include Singleton

    COLLECTOR_LIST_KEY = :ro_collector

    def initialize
      @subscriber ||= ActiveSupport::Notifications.subscribe(/\A[^!]/, self)
    end

    def call(event)
      puts "Collecting event #{event.name} #{event.payload}"
      return if ActiveSupport::IsolatedExecutionState[COLLECTOR_LIST_KEY].blank?

      ActiveSupport::IsolatedExecutionState[COLLECTOR_LIST_KEY].each do |key|
        if (events = ActiveSupport::IsolatedExecutionState[key])
          events << event
        end
      end

    end

    def generate_collector_key
      "collector:#{Object.new.object_id}"
    end


    def collect_events
      events = []
      key = generate_collector_key
      ActiveSupport::IsolatedExecutionState[COLLECTOR_LIST_KEY] ||= []
      ActiveSupport::IsolatedExecutionState[COLLECTOR_LIST_KEY] << key
      ActiveSupport::IsolatedExecutionState[key] = events
      result = yield
      [events, result]
    rescue Exception => e
      e.instance_variable_set(:@_trace_events, events)
      raise
    ensure
      ActiveSupport::IsolatedExecutionState[COLLECTOR_LIST_KEY].delete(key)
      ActiveSupport::IsolatedExecutionState.delete(key)
    end
  end
end