module RailsObservatory
  class ChartChannel < ApplicationCable::Channel
    periodically every: 10.seconds do
      broadcast_to channel_key, latest_data
    end


    def subscribed
      stream_for channel_key
    end

    def unsubscribed
      # Any cleanup needed when channel is unsubscribed
    end

    def init
      broadcast_to channel_key, latest_data
    end

    private

    def channel_key
      @channel_key ||= SecureRandom.uuid
    end

    def latest_data
      series = RedisTimeSeries.where(**labels).slice(duration.seconds.ago..).downsample(40, using: agg_method.to_sym)
      series.map { |s| { name: s.name.split("/").last, data: s.filled_data } }
    end

    def agg_method
      params[:series][:agg_method].presence_in(%w[sum avg]) || :avg
    end

    def samples
      params[:samples].to_i.clamp(1..100)
    end

    def duration
      (params[:duration] || 1.hour).to_i
    end

    def labels
      @labels ||=
        begin
          label_params = params[:series].without(:samples, :agg_method, :controller, :action, :format, :children, :duration).deep_symbolize_keys
          if params[:series][:children] == true
            label_params.delete(:name)
            label_params[:parent] = params[:series][:name]
          end
          label_params
        end
    end

  end
end
