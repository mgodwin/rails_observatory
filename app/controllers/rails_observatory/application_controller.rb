module RailsObservatory
  class ApplicationController < ::ActionController::Base

    def set_duration
      if params[:duration].presence
        session[:duration] = params[:duration].to_i
      end
    end

    def duration
      ActiveSupport::Duration.build((session[:duration] || 1.hour).to_i)
    end
    helper_method :duration

    def time_range
      @time_range ||= (duration.seconds.ago..)
    end

    def time_slice_start
      time_range.begin.to_i * 1000
    end

    def time_slice_end
      time = time_range.end.nil? ? Time.now.to_i : time_range.end.to_i
      time * 1000
    end

    def buckets_for_chart
      duration_sec = (time_slice_end - time_slice_start) / 1000
      # 10 second buckets are the smallest resolution we have
      buckets_in_time_frame = (duration_sec / 10.0).to_i
      [120, buckets_in_time_frame].min
    end

  end
end
