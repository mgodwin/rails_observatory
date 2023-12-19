module RailsObservatory
  class RequestsController < ApplicationController

    before_action :set_duration

    def index
      CalculateProfitJob.perform_later
      @time_range = (duration.seconds.ago..)

      @count_series = RequestTimeSeries.where(type: 'count')
      @latency_series = RequestTimeSeries.where(type: 'latency')
      # RequestTimeSeries.where(parent: 'latency').slice(@time_range)
      # RequestTimeSeries.where(type: 'errors').slice(@time_range)

      if params[:controller_action].blank?
        @count_by_controller = RequestTimeSeries.where(type:'count', action: '*').slice(@time_range).downsample(1, using: :sum).sort_by { _1.data.dig(0,1).to_i * -1 }
        @latency_by_controller = RequestTimeSeries.where(type:'latency', action: '*').slice(@time_range).downsample(1, using: :avg).index_by { _1.labels[:action] }
      end
      @events = RequestsStream.all.lazy.take(25)
    end

    def show
      @time_range = (1.hour.ago..)
      # TODO: Munge together all streams into one and store in redis sorted set
      @events = RequestsStream.all.select { |e| e.payload[:request_id] == params[:id]}
      @req = @events.find { |e| e.type == 'process_action.action_controller' }
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
