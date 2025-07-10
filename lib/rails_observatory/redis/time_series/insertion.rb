require 'benchmark'

SCRIPT = File.read(File.join(File.dirname(__FILE__), 'timing_script.lua'))
INCREMENT_SCRIPT = File.read(File.join(File.dirname(__FILE__), 'increment_script.lua'))

class RedisScript

  def self.redis
    Rails.configuration.rails_observatory.redis
  end

  def redis
    self.class.redis
  end

  def initialize(lua_string)
    @script = lua_string
  end

  def call(*args)
    @sha1 ||= load_script
    redis.call("EVALSHA", @sha1, 0, *args)
  rescue => e
    if e.message =~ /NOSCRIPT/
      @sha1 = load_script
      retry
    else
      raise e
    end
  end

  def load_script
    redis.call('SCRIPT', 'LOAD', @script)
  end

end

TIMING_SCRIPT = RedisScript.new(SCRIPT)
INCREMENT_CALL = RedisScript.new(INCREMENT_SCRIPT)

module RailsObservatory

  class TimeSeries
    module Insertion

      def distribution(name, value, at: Time.now, labels: {})
        prefixed_name = begin
                          if defined?(self::PREFIX)
                            [self::PREFIX, name].join('.')
                          else
                            name
                          end
                        end
        timestamp = (at.to_f * 1000).to_i
        TIMING_SCRIPT.call(prefixed_name, value, timestamp, labels.to_a.flatten.map(&:to_s))
      end
      alias_method :record_timing, :distribution

      def increment(name, at: Time.now, labels: {})

        prefixed_name = begin
                          if defined?(self::PREFIX)
                            [self::PREFIX, name].join('.')
                          else
                            name
                          end
                        end
        timestamp = (at.to_f * 1000).to_i
        INCREMENT_CALL.call(prefixed_name, timestamp, labels.to_a.flatten.map(&:to_s))
      end
      alias_method :record_occurrence, :increment
    end
  end
end