module RailsObservatory
  class JobTimeSeries < RedisTimeSeries

    PREFIX = "job"

    def queue_name
      labels[:queue_name]
    end

    def job_class
      labels[:job_class]
    end
    def self.where(name: nil, queue_name: nil, job_class: nil)
      super(name: [PREFIX, name].join('.'), queue_name:, job_class:)
    end

    def self.increment(name, queue_name:, job_class:)
      super([PREFIX, name].join('.'), labels: {queue_name:, job_class:})
    end

    def self.distribution(name, duration, queue_name:, job_class:)
      super([PREFIX, name].join('.'), duration, labels: {queue_name:, job_class:})
    end
  end
end