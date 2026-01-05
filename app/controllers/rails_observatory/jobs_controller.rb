module RailsObservatory
  class JobsController < ApplicationController
    layout "rails_observatory/application_time_slice"

    def index
      JobTrace.ensure_index
      @time_range = (duration.seconds.ago..)

      # For "By Queue" table
      @count_by_queue = RedisTimeSeries.query_value("job.count", :sum)
        .where(queue_name: true)
        .group("queue_name")
        .select { it.value > 0 }
        .sort_by(&:value)
        .reverse

      # For "By Job" table
      @count_by_job = RedisTimeSeries.query_value("job.count", :sum)
        .where(job_class: true)
        .group("job_class")
        .select { it.value > 0 }
        .sort_by(&:value)
        .reverse

      @latency_by_job = RedisTimeSeries.query_value("job.latency", :avg)
        .where(job_class: true)
        .group("job_class")
        .to_a
        .index_by { it.labels["job_class"] }
    end

    def show
      @job = JobTrace.find(params[:id])
      @events = @job.events
    end
  end
end
