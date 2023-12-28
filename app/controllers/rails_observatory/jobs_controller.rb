module RailsObservatory
  class JobsController < ApplicationController

    before_action :set_duration

    def index

      @time_range = (duration.seconds.ago..)
      @recent_jobs = JobsStream.all.take(10)
      @by_queue = JobTimeSeries.where(name: "count", queue_name: '*').slice(@time_range)
                               .downsample(1, using: :sum)
                               .reject(&:empty?)
                               .sort_by(&:value)

      @by_job = JobTimeSeries.where(name: "count", job_class: '*').slice(@time_range)
                             .downsample(1, using: :sum)
                             .reject(&:empty?)
                             .sort_by(&:value)

      @perform_count = JobTimeSeries.where(name: "count").slice(@time_range)
    end
  end
end
