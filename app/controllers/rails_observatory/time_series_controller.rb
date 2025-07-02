module RailsObservatory
  class TimeSeriesController < ApplicationController

    before_action :ensure_name

    def index

      series = TimeSeries.where(**labels)
                         .slice(duration.seconds.ago..)
                         .downsample(samples, using: agg_method)

      render json: series.map { |s| { name: s.name.split("/").last, data: s.filled_data } }, status: :ok
    end

    private

    def ensure_name
      unless params[:name].present?
        render json: { error: "name is required" }, status: :bad_request
      end
    end

    def labels
      @labels ||=
        begin
          label_params = params.without(:samples, :agg_method, :controller, :action, :format, :children).permit!.to_h.deep_symbolize_keys
          if params[:children] == "true"
            label_params.delete(:name)
            label_params[:parent] = params[:name]
          end
          label_params
        end
    end

    def agg_method
      params[:agg_method].presence_in(%w[sum avg]) || :avg
    end

    def samples
      params[:samples].to_i.clamp(1..100)
    end
  end
end