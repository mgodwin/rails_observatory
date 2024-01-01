module RailsObservatory
  class JobTimeSeries < Redis::TimeSeries

    PREFIX = "job"

    def queue_name
      labels[:queue_name]
    end

    def job_class
      labels[:job_class]
    end
    def self.where(name: nil, queue_name: nil, job_class: nil)
      super(name:, queue_name:, job_class:)
    end
  end
end