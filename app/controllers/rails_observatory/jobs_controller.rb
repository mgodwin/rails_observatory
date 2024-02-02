module RailsObservatory
  class JobsController < ApplicationController

    before_action :set_duration

    around_action :set_time_range

    def index
      Job.ensure_index
      @recent_jobs = Job.all.take(10)
    end

    def set_time_range
      TimeSeries.with_slice(duration.seconds.ago..) do
        yield
      end
    end
  end
end
