module RailsObservatory
  class LogsController < ApplicationController

    before_action :set_duration
    def index

      @time_range = (duration.seconds.ago..)
      @recent_logs = LogsStream.all.take(100)
    end
  end
end
