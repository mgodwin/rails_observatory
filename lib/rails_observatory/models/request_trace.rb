require_relative './redis_model'
module RailsObservatory
  class RequestTrace < RedisModel

    attribute :request_id, :string
    attribute :status, :integer
    attribute :http_method, :string
    attribute :path, :string
    attribute :action, :string
    attribute :format, :string
    attribute :error, :boolean
    attribute :route_pattern, :string
    attribute :time, :float
    attribute :duration, :float
    attribute :allocations, :integer, indexed: false

    alias_attribute :id, :request_id
    alias_attribute :name, :action

  end
end