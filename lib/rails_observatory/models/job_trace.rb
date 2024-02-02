require_relative './redis_model'
module RailsObservatory
  class JobTrace < RedisModel

    attribute :job_id, :string
    attribute :queue_name, :string
    attribute :queue_adapter, :string
    attribute :job_class, :string
    attribute :executions, :integer
    attribute :error, :boolean
    attribute :time, :float
    attribute :allocations, :integer, indexed: false
    attribute :queue_latency, :float, indexed: false
    attribute :duration, :float, indexed: false

    alias_attribute :id, :job_id
    alias_attribute :name, :job_class
  end
end