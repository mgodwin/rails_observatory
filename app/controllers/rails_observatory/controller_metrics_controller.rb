module RailsObservatory
  class ControllerMetricsController < ApplicationController

    before_action :set_duration

    def index
      @time_range = (duration.seconds.ago..)
      @request_count_range = TimeSeries.where(name: "process_action.action_controller.count", action: nil, method: nil, format: nil, status: nil).first
      @latency_series = TimeSeries.where(name:"process_action.action_controller.latency", action:nil, method: nil, format: nil, status: nil).first
      @controller_metrics = ControllerMetric.find_all_in_time_frame(@time_range)
      @latency_composition = ControllerMetric.latency_composition_series_set
      @errors = ControllerMetric.errors
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
