module RailsObservatory
  class ErrorsController < ApplicationController

    def index
      Error.ensure_index
      @errors = Error.all
      @series_by_fingerprint = RedisTimeSeries.where(name: "error.count", fingerprint: @errors.map(&:fingerprint))
                                              .downsample(12, using: :sum)
                                              .index_by { _1.labels[:fingerprint] }
      @count_by_fingerprint = RedisTimeSeries.where(name: "error.count", fingerprint: @errors.map(&:fingerprint)).group(:fingerprint).sum
    end

    def show
      @time_range = (1.hour.ago..)
      @error = Error.find(params[:id])
      series = RedisTimeSeries.where(name: "error.count", fingerprint: @error.fingerprint)
                              .downsample(24, using: :sum)
      @count = RedisTimeSeries.where(name: "error.count", fingerprint: @error.fingerprint).slice(2.years.ago..).downsample(1, using: :sum).first.value
      # puts series.slice(1.day.ago..).to_a.size
      @past_24_hours = series.slice(24.hours.ago..).first
      @past_7_days = series.slice(7.days.ago..).first
      @past_30_days = series.slice(30.days.ago..).first
    end
  end
end
