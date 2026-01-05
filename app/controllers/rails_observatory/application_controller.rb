module RailsObservatory
  class ApplicationController < ::ActionController::Base
    before_action :set_session_time_defaults
    before_action :update_session_time
    around_action :set_time_range
    def set_time_range
      RedisTimeSeries.with_slice(time_slice) do
        yield
      end
    end

    def clear_session_time
      session.delete(:ts)
      session.delete(:te)
      session.delete(:duration)
    end

    def session_time_blank?
      session[:ts].blank? && session[:te].blank? && session[:duration].blank?
    end

    def set_session_time_defaults
      if session_time_blank?
        session[:duration] = 1.hour
      end
    end

    def update_session_time
      return if params.slice(:ts, :te, :duration).values.all?(&:blank?)

      clear_session_time

      if params[:ts].present? && params[:te].present?
        session[:ts] = params[:ts].to_i
        session[:te] = params[:te].to_i
      elsif params[:duration].present?
        session[:duration] = params[:duration].to_i
      end
    end

    def duration
      if relative_time_slice?
        ActiveSupport::Duration.build((session[:duration] || 1.hour).to_i)
      else
        ActiveSupport::Duration.build(time_slice.end - time_slice.begin)
      end
    end
    helper_method :duration

    private

    def relative_time_slice?
      session[:duration].present?
    end

    def time_start
      @time_start ||= relative_time_slice? ? time_end - duration : Time.at(session[:ts].to_i)
    end

    def time_end
      @time_end ||= relative_time_slice? ? Time.now : Time.at(session[:te].to_i)
    end

    def time_slice
      @time_slice ||= Range.new(time_start, time_end)
    end
    helper_method :time_slice, :time_start, :time_end, :relative_time_slice?
  end
end
