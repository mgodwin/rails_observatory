module RailsObservatory
  class ControllerMetricsController < ApplicationController

    before_action :set_duration

    def index
      @time_range = (duration.seconds.ago..)
      @request_count_range = TimeSeries.where(name: "process_action.action_controller.count", action: nil, method: nil, format: nil, status: nil).first[@time_range].rollup(buckets: 80)
      @latency_series = TimeSeries.where(name:"process_action.action_controller.latency", action:nil, method: nil, format: nil, status: nil).first[@time_range].rollup(buckets: 120)
      @controller_metrics = ControllerMetric.find_all_in_time_frame(@time_range)
      @runtime_breakdown = ControllerMetric.runtime_breakdown[@time_range].rollup(buckets: 120)
    end

    def show
      @time_range = (1.hour.ago..)
      @controller_metric = ControllerMetric.find(params[:id])
    end

    private

    def set_duration
      if params[:duration].presence
        session[:duration] = params[:duration].to_i
      end
    end

    def duration
      ActiveSupport::Duration.build((session[:duration] || 1.hour).to_i)
    end
    helper_method :duration
  end
end
