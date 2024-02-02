module RailsObservatory
  class RequestsController < ApplicationController

    def index
      # CalculateProfitJob.perform_later
      # NewUserMailer.greeting.deliver_later
      @time_range = (duration.seconds.ago..)

      # page_through(query, page_size: 25).each_result do |event|
      #
      # end
      if params[:controller_action].present?

      else
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
      @filtered_events = @request.events.without('process_middleware.action_dispatch')
      @icicle_chart_series = @request.events.without('process_middleware.action_dispatch').to_series
    end

  end
end
