module RailsObservatory
  class ControllerMetric
    def self.find(id)
      action = $redis.call("HGET", "ids_to_controller", id)
      new(action)
    end

    def self.find_all_in_time_frame(time_frame)
      all = TimeSeries.where(name: 'process_action.action_controller.count', action: '*', method: nil, format: nil, status: nil)
      all.select { |series| series.last_timestamp > time_frame.begin.to_i }.map { |series| new(series.info['labels']['action']) }
    end

    def self.runtime_breakdown
      TimeSeries.where(name: 'process_action.action_controller.view_runtime', action: '*', method: nil, format: nil, status: nil).first
    end

    def self.requests

    end

    def self.latency

    end

    def self.errors

    end

    attr_reader :action
    def initialize(action)
      @action = action
    end

    def id
      @id ||= $redis.call("HGET", "controller_to_ids", @action)
    end

    def request_count(time_frame)
      TimeSeries.where(name: 'process_action.action_controller.count', action: @action, method: nil, format: nil, status: nil).first[time_frame].reduce
    end
  end
end