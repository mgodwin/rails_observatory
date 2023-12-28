module RailsObservatory
  class ErrorsController < ApplicationController

    before_action :set_duration

    def index
      @time_range = (24.hours.ago..)
      @errors = ErrorSet.new('errors_by_recency').take(25)
      @series_by_fingerprint = ErrorTimeSeries.where(fingerprint: @errors.map(&:fingerprint))
                                              .slice(@time_range)
                                              .downsample(12, using: :sum)
                                              .index_by(&:fingerprint)
    end

    def show
      @time_range = (1.hour.ago..)
      @error = Error.find(params[:id])
      series = ErrorTimeSeries.where(fingerprint: @error.fingerprint).downsample(24, using: :sum)
      # puts series.slice(1.day.ago..).to_a.size
      @past_24_hours = series.slice(24.hours.ago..).first
      @past_7_days = series.slice(7.days.ago..).first
      @past_30_days = series.slice(30.days.ago..).first
    end
  end
end
