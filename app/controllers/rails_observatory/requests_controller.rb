module RailsObservatory
  class RequestsController < ApplicationController

    def index
      # CalculateProfitJob.perform_later
      # NewUserMailer.greeting.deliver_later
      @time_range = (duration.seconds.ago..)

      # RequestTimeSeries.where(parent: 'latency').slice(@time_range)
      # RequestTimeSeries.where(type: 'errors').slice(@time_range)

      # @events = RequestsStream.all.lazy
      # page_through(query, page_size: 25).each_result do |event|
      #
      # end
      # Request.ingested.order(:desc).paged_each(page_size: 25).lazy.take(25)
      # @events = Request.ingested.order(:desc).limit(25)
      if params[:controller_action].present?

        @events = @events.select { |e| e.controller_action == params[:controller_action] }
        @count_series = @count_series.where(action: params[:controller_action])
        @latency_series = @latency_series.where(action: params[:controller_action])
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

      @events = Request.ingested.order(:desc).limit(25)
    end

    def show
      @time_range = (1.hour.ago..)
      @request = Request.find(params[:id])

      ActiveSupport::Notifications.instrument("set.redis") do
        @all_events = @request.events.to_a
      end
      @all_events.each_cons(2) do |a, b|
        if b['start_at'] > a['start_at'] && b['end_at'] < a['end_at']
          b['depth'] = a['depth'].to_i + 1
        else
          b['depth'] = a['depth']
        end
      end


      @all_events.each do |ev|
        ev['self_time'] = ev['duration'] - @all_events.select { _1['depth'] == (ev['depth'].to_i + 1) && _1['end_at'] < ev['end_at'] }.pluck('duration').sum
      end

      @middleware_events = @all_events.select { _1['name'] == 'process_middleware.action_dispatch' }
      @filtered_events = @all_events.reject { _1['name'] == 'process_middleware.action_dispatch' }
      first_event = @filtered_events.first['start_at']
      grouped_events = @filtered_events.group_by { _1['name'].split('.').last }


      @events = grouped_events.map do |name, events|

        {
          name: name,
          data: events.map do |ev|

            {
              x: ev['depth'].to_i.to_s,
              y: [ev['start_at'] - first_event, ev['end_at'] - first_event],
              event_self_time: ev['self_time'],
              event_name: ev['name'].split('.').first,
              start_at: ev['start_at'],
            }
          end
        }
      end
    end

  end
end
