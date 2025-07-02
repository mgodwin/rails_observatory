require_relative '../redis/redis_model'
require_relative './events'
require_relative './logs'

module RailsObservatory
  class JobTrace < RedisModel
    include Events
    include Logs

    def self.key_prefix
      "jt"
    end

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