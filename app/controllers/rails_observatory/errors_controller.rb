module RailsObservatory
  class ErrorsController < ApplicationController

    before_action :set_duration

    def index
      @errors = ErrorSet.new('errors_by_recency').take(25)
      # @events = ErrorsStream.all.lazy.take(25)
    end

    def show
      @time_range = (1.hour.ago..)
      @error = Error.find(params[:id])
    end

  end
end
