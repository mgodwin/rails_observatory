module RailsObservatory
  class JobSerializer
    def serialize(job)
      { class: job.class.name, job_id: job.job_id, queue_name: job.queue_name }
    end

    def self.klass
      ActiveJob::Base
    end
  end
end