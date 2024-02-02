module RailsObservatory
  class ApplicationController < ::ActionController::Base

    before_action :set_duration
    around_action :set_time_range
    def set_time_range
      TimeSeries.with_slice(duration.seconds.ago..) do
        yield
      end
    end

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
