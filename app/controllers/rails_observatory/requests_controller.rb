module RailsObservatory
  class RequestsController < ApplicationController

    before_action :ensure_indexed, only: :index
    layout 'rails_observatory/application_time_slice'

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
    end

    def recent
      @traces = RequestTrace.all.where(time: 5.seconds.ago..).limit(20)
      render partial: 'rails_observatory/requests/recent_requests', layout: false
    end

    def show
      @request = RequestTrace.find(params[:id])
      @middleware_events = @request.events.only('process_middleware.action_dispatch')
      @events = @request.events
      @icicle_chart_series = @events.to_series
    end

    private

    def ensure_indexed
      RequestTrace.ensure_index
    end

  end
end
