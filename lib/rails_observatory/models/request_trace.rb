require_relative './events'
require_relative './logs'
module RailsObservatory
  class RequestTrace < RedisModel
    include Events
    include Logs

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

    def self.key_prefix
      "rt"
    end

  end
end