module RailsObservatory
  class RequestsController < ApplicationController

    before_action :set_duration

    def index
      CalculateProfitJob.perform_later
      @time_range = (duration.seconds.ago..)
      Requests::CountMetric.series
      @request_count_range = RedisTimeSeries.where(name: "process_action.action_controller.count", action: nil, method: nil, format: nil, status: nil).first
      @latency_series = RedisTimeSeries.where(name:"process_action.action_controller.latency", action:nil, method: nil, format: nil, status: nil).first

      if params[:controller_action].blank?
        @controller_metrics = ControllerMetric.find_all_in_time_frame(@time_range)
      end
      @latency_composition = ControllerMetric.latency_composition_series_set
      @errors = ControllerMetric.errors
      @events = RequestsStream.all.lazy.take(10)
    end

    def show
      @time_range = (1.hour.ago..)
      @events = EventStream.from('events').events.select { |e| e.payload['request_id'] == params[:id]}
      @req = @events.find { |e| e.name == 'process_action.action_controller' }
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
