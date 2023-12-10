module RailsObservatory
  class ControllerMetric

    EVENT_PREFIX = "process_action.action_controller"

    def self.find(id)
      action = $redis.call("HGET", "ids_to_controller", id)
      new(action)
    end

    def self.find_all_in_time_frame(time_frame)
      all = TimeSeries.where(**global_scope.merge(name: "#{EVENT_PREFIX}.count", action: '*'))
      all.select { |series| series.last_timestamp > time_frame.begin.to_i }.map { |series| new(series.info['labels']['action']) }
    end

    def self.latency_composition_series_set
      TimeSeries.where(**global_scope.merge(parent: "#{EVENT_PREFIX}.latency", compaction: 'avg'))
    end

    def self.requests

    end

    def self.latency

    end

    def self.errors
      TimeSeries.where(**global_scope.merge(name: "#{EVENT_PREFIX}.count/errors")).first
    end

    attr_reader :action

    def initialize(action)
      @action = action
    end

    def id
      @id ||= $redis.call("HGET", "controller_to_ids", @action)
    end

    def request_count(time_frame)
      TimeSeries.where(**action_scope.merge(name: "#{EVENT_PREFIX}.count")).first[time_frame].reduce
    end

    def avg_latency(time_frame)
      TimeSeries.where(**action_scope.merge(name: "#{EVENT_PREFIX}.latency", compaction: 'avg')).first[time_frame].reduce
    end

    private

    def self.global_scope
      { action: nil, method: nil, format: nil, status: nil }
    end

    def action_scope
      { action: @action, method: nil, format: nil, status: nil }
    end

  end
end