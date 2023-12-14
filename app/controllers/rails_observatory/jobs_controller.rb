module RailsObservatory
  class JobsController < ApplicationController

    before_action :set_duration
    def index

      @time_range = (duration.seconds.ago..)
      @recent_jobs = JobsStream.all.take(10)
    end
  end
end
