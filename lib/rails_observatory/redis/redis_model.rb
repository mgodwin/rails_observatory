require_relative '../serializers/serializer'
require_relative '../event_collection'
require_relative './time_series'
require_relative './redis_model/query_builder'
require 'zlib'

# RedisModel is a base class for models that interact with Redis.
# Internally it uses Redis Full Text Search (FT) for indexing and querying.
# It can also compress attributes to save space in Redis.
#
# Records are stored as JSON keys in Redis with a specific key prefix which is later
# used to create an index for searching.
# Example:
#   a key prefix of `rt` will result in keys like `rt:12347`
#
# Using RedisModel.create_redis_index you can index all saved models using Redis Full Text Search.
# This command takes a key prefix to know which keys to index.
#
# Once an index is created, you can find and search for records using an ActiveRecord inspired
# query interface.
#
# ## Compressed Attributes
# This class also supports compression of attributes using zlib.
# Compressed attributes are stored in Redis as separate keys with a specific format.
# e.g. a compressed attribute `data` for a record with id `12347` will be stored as `rt_data:12347`
# Compressed attributes are not included in the JSON representation of the model, and are not searchable.
# They can be used after loading the model like a normal attribute and will be automatically decompressed when accessed.
module RailsObservatory
  class RedisModel
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    class NotFound < StandardError; end

    class << self
      attr_accessor :indexed_attributes
      attr_accessor :compressed_attributes
    end

    define_model_callbacks :save

    def self.attribute(name, *args, indexed: true, compressed: false, **rest)
      if indexed
        self.indexed_attributes ||= []
        indexed_attributes << name
      end
      if compressed
        self.compressed_attributes ||= []
        compressed_attributes << name.to_s
      end
      super(name, *args, **rest)
    end

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
      QueryBuilder.new(self)
    end

    def self.find(id)
      result = redis.call("JSON.GET", key_name(id), "$") || raise(NotFound, "Could not find #{name} with id #{id}")
      attrs = JSON.parse(result).first

      compressed_attributes.each do |attr|
        val = redis.call("GET", [key_prefix, attr].join("_") + ":#{id}")
        attrs.merge!(attr => JSON.parse(Zlib.gunzip(val)))
      end

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

    def attribute_names_for_serialization
      attributes.keys - self.class.compressed_attributes
    end

    def save
      run_callbacks :save do
        redis.multi do |r|
          r.call("JSON.SET", self.class.key_name(id), "$", JSON.generate(as_json))
          self.class.compressed_attributes.each do |attr|
            compressed_value = Zlib.gzip(JSON.generate(@attributes.fetch_value(attr)), level: Zlib::BEST_COMPRESSION)
            r.call("SET", [self.class.key_prefix, attr].join("_") + ":#{id}", compressed_value)
          end
          r.call("EXPIRE", self.class.key_name(id), 1.day.to_i)
        end
      end
    end

  end
end