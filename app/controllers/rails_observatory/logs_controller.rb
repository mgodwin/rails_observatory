module RailsObservatory
  class LogsController < ApplicationController

    before_action :set_duration
    def index
      @logs_by_type = LogTimeSeries.where(name: 'count').slice(time_range).downsample(buckets_for_chart, using: :sum)
      @recent_logs = LogsStream.all.take(100)
    end
  end
end
