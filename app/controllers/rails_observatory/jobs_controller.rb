module RailsObservatory
  class JobsController < ApplicationController

    before_action :set_duration

    around_action :set_time_range

    def index
      JobTrace.ensure_index
      @recent_jobs = JobTrace.all.take(10)
    end

    def show
      @job = JobTrace.find(params[:id])
      @events = @job.events

    end

    def set_time_range
      TimeSeries.with_slice(duration.seconds.ago..) do
        yield
      end
    end
  end
end
