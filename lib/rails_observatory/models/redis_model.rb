require_relative '../serializers/serializer'
require_relative './event_collection'
require_relative '../redis/time_series'
module RailsObservatory
  class RedisModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    class NotFound < StandardError; end

    class << self
      attr_accessor :indexed_attributes
    end

    def self.attribute(name, *args, indexed: true, **rest)
      if indexed
        self.indexed_attributes ||= []
        indexed_attributes << name
      end
      super(name, *args, **rest)
    end

    attribute :events, indexed: false

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def redis
      self.class.redis
    end

    def self.key_prefix
      name.demodulize.underscore
    end

    def self.key_name(id)
      "#{key_prefix}:#{id}"
    end

    def self.count
      total, *results = redis.call("FT.SEARCH", index_name, '*', "SORTBY", "time", "DESC")
      total
    end

    def self.all
      total, *results = redis.call("FT.SEARCH", index_name, '*', "SORTBY", "time", "DESC")
      Hash[*results].values.map(&:last).map { JSON.parse(_1) }.map { new(_1) }
    end

    def self.find(id)
      result = redis.call("JSON.GET", key_name(id), "$") || raise(NotFound, "Could not find #{name} with id #{id}")
      attrs = JSON.parse(result).first
      self.new(attrs)
    end

    ATTRIBUTE_TYPE_TO_REDIS_TYPE = {
      string: "TEXT",
      integer: "NUMERIC",
      float: "NUMERIC",
      boolean: "TAG"
    }

    def self.index_name
      "#{key_prefix}-idx"
    end

    def self.create_redis_index
      schema = indexed_attributes.flat_map do |attr|
        ["$.#{attr}", "AS", "#{attr}", ATTRIBUTE_TYPE_TO_REDIS_TYPE[attribute_types[attr.to_s].type]]
      end
      redis.call("FT.CREATE", index_name, "ON", "JSON", "PREFIX", "1", key_prefix, "SCHEMA", *schema)
    end

    def self.index_info
      info = Hash[*redis.call("FT.INFO", index_name)]
      info['attributes'] = info['attributes'].map { Hash[*_1] }
      info['index_definition'] = Hash[*info['index_definition']]
      info
    end

    def self.ensure_index
      redis.call("FT._LIST").include?(index_name) || create_redis_index
    end

    def save
      redis.call("JSON.SET", self.class.key_name(id), "$", JSON.generate(attributes))
    end

    def mail_events
      events.only('enqueue.action_job', 'deliver.action_mailer')
            .reject {_1['name'] == 'enqueue.action_job' && _1.dig('payload', 'job', 'class') != 'ActionMailer::MailDeliveryJob' }
    end

    def events
      attr_value = super
      return nil if attr_value.nil?
      EventCollection.new(attr_value)
    end
  end
end