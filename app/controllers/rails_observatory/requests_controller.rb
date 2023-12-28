module RailsObservatory
  class RequestsController < ApplicationController

    before_action :set_duration

    def index
      CalculateProfitJob.perform_later
      @time_range = (duration.seconds.ago..)

      @count_series = RequestTimeSeries.where(name: 'count').slice(@time_range).downsample(buckets_for_chart, using: :sum)
      @latency_series = RequestTimeSeries.where(name: 'latency').slice(@time_range).downsample(buckets_for_chart, using: :avg)
      # RequestTimeSeries.where(parent: 'latency').slice(@time_range)
      # RequestTimeSeries.where(type: 'errors').slice(@time_range)

      if params[:controller_action].blank?
        @count_by_controller = RequestTimeSeries.where(name:'count', action: '*').slice(@time_range).downsample(1, using: :sum)
                                                .select(&:value)
                                                .sort_by(&:value).reverse
        @latency_by_controller = RequestTimeSeries.where(name:'latency', action: '*').slice(@time_range).downsample(1, using: :avg)
                                                  .index_by { _1.labels[:action] }
      end
      @events = RequestsStream.all.lazy.take(25)
    end


    def time_slice_start
      @time_range.begin.to_i * 1000
    end

    def time_slice_end
      time = @time_range.end.nil? ? Time.now.to_i : @time_range.end.to_i
      time * 1000
    end

    def buckets_for_chart
      duration_sec = (time_slice_end - time_slice_start) / 1000
      # 10 second buckets are the smallest resolution we have
      buckets_in_time_frame = (duration_sec / 10.0).to_i
      [120, buckets_in_time_frame].min
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
