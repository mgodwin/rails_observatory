module RailsObservatory
  class JobsController < ApplicationController

    before_action :set_duration
    def index

      @time_range = (duration.seconds.ago..)
    end
  end
end
