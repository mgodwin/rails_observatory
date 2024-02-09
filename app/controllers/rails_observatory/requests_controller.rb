module RailsObservatory
  class RequestsController < ApplicationController

    def index
      @time_range = (duration.seconds.ago..)

      if params[:controller_action].blank?
        @count_by_controller = TimeSeries.where(name: 'request.count', action: '*')
                                         .slice(@time_range)
                                         .downsample(1, using: :sum)
                                         .select { _1.value > 0 }
                                         .sort_by(&:value)
                                         .reverse

        @latency_by_controller = TimeSeries.where(name: 'request.latency', action: '*')
                                           .slice(@time_range)
                                           .downsample(1, using: :avg)
                                           .index_by { _1.labels[:action] }
      end

      RequestTrace.ensure_index
      @events = RequestTrace.all
    end

    def show
      @request = RequestTrace.find(params[:id])
      @middleware_events = @request.events.only('process_middleware.action_dispatch')
      @events = @request.events
      @icicle_chart_series = @events.to_series
    end

  end
end
