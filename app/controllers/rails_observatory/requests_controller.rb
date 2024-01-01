module RailsObservatory
  class RequestsController < ApplicationController


    def index
      CalculateProfitJob.perform_later
      NewUserMailer.greeting.deliver_later
      @time_range = (duration.seconds.ago..)

      @count_series = RequestTimeSeries.where(name: 'count').slice(@time_range).downsample(buckets_for_chart, using: :sum)
      @latency_series = RequestTimeSeries.where(name: 'latency').slice(@time_range).downsample(buckets_for_chart, using: :avg)
      # RequestTimeSeries.where(parent: 'latency').slice(@time_range)
      # RequestTimeSeries.where(type: 'errors').slice(@time_range)

      @events = RequestsStream.all.lazy
      if params[:controller_action].present?
        @events = @events.select { |e| e.controller_action == params[:controller_action] }
        @count_series = @count_series.where(action: params[:controller_action])
        @latency_series = @latency_series.where(action: params[:controller_action])
      else
        @count_by_controller = RequestTimeSeries.where(name: 'count', action: '*')
                                                .slice(@time_range)
                                                .downsample(1, using: :sum)
                                                .select { _1.value > 0 }
                                                .sort_by(&:value)
                                                .reverse

        @latency_by_controller = RequestTimeSeries.where(name: 'latency', action: '*')
                                                  .slice(@time_range)
                                                  .downsample(1, using: :avg)
                                                  .index_by { _1.labels[:action] }
      end

      @events = @events.take(25)
    end

    def show
      @time_range = (1.hour.ago..)
      # TODO: Munge together all streams into one and store in redis sorted set
      @events = RequestsStream.all.lazy.select { |e| e.payload[:request_id] == params[:id] }
      @req = @events.find { |e| e.type == 'process_action.action_controller' }
    end
  end
end
