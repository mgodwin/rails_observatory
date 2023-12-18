module RailsObservatory
  class ErrorsController < ApplicationController

    before_action :set_duration

    def index
      @library = 'action_controller'
      @time_range = (duration.seconds.ago..)
      @errors = ErrorSet.new('errors_by_recency').take(25)
      # @events = ErrorsStream.all.lazy.take(25)
    end

    def show
      @time_range = (1.hour.ago..)
      @controller_metric = ControllerMetric.find(params[:id])
    end

    private

    def set_duration
      if params[:duration].presence
        session[:duration] = params[:duration].to_i
      end
    end

    def duration
      ActiveSupport::Duration.build((session[:duration] || 1.hour).to_i)
    end
    helper_method :duration
  end
end
