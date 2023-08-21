module RailsObservatory
  class ControllerMetricsController < ApplicationController
    def index
      @time_frame = (1.hour.ago..)
      @all_series = TimeSeries.where(name: 'process_action.action_controller.count', action: '*', method: nil, format: nil, status: nil)
      @all_series = @all_series.select { |series| series.last_timestamp > @time_frame.begin.to_i }
      @request_count_range = TimeSeries.where(name: "process_action.action_controller.count", action: nil).first[@time_frame].rollup(buckets: 80)
      @latency_range = TimeSeries.where(name:"process_action.action_controller.latency", action:nil).first[@time_frame].rollup(buckets: 120)
      @controller_metrics = ControllerMetric.in_time_frame(@time_frame)
    end

    def show
      @time_frame = (1.hour.ago..)
      @controller_metric = ControllerMetric.find(params[:id])
    end
  end
end
