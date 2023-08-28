module RailsObservatory
  class ControllerMetricsController < ApplicationController
    def index
      @time_range = (duration.seconds.ago..)
      puts "time_range: #{@time_range} #{duration} #{params[:duration]}"
      @all_series = TimeSeries.where(name: 'process_action.action_controller.count', action: '*', method: nil, format: nil, status: nil)
      @all_series = @all_series.select { |series| series.last_timestamp > @time_range.begin.to_i }
      @request_count_range = TimeSeries.where(name: "process_action.action_controller.count", action: nil, method: nil, format: nil, status: nil).first[@time_range].rollup(buckets: 80)
      @latency_range = TimeSeries.where(name:"process_action.action_controller.latency", action:nil, method: nil, format: nil, status: nil).first[@time_range].rollup(buckets: 120)
      @controller_metrics = ControllerMetric.in_time_frame(@time_range)
    end

    def show
      @time_range = (1.hour.ago..)
      @controller_metric = ControllerMetric.find(params[:id])
    end

    private

    def duration
      (params[:duration].presence || 1.hour).to_i
    end
  end
end
