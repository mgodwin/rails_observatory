require 'benchmark'

SCRIPT = File.read(File.join(File.dirname(__FILE__), 'timing_script.lua'))
INCREMENT_SCRIPT = File.read(File.join(File.dirname(__FILE__), 'increment_script.lua'))

class RedisScript
  def initialize(lua_string)
    @script = lua_string
  end

  def call(*args)
    @sha1 ||= load_script
    $redis.call("EVALSHA", @sha1, 0, *args)
  rescue => e
    if e.message =~ /NOSCRIPT/
      @sha1 = load_script
      retry
    else
      raise e
    end
  end

  def load_script
    $redis.call('SCRIPT', 'LOAD', @script)
  end

end

TIMING_SCRIPT = RedisScript.new(SCRIPT)
INCREMENT_CALL = RedisScript.new(INCREMENT_SCRIPT)

module RailsObservatory
  module RedisTimeSeries::Insertion

    # TODO: These need to take in a timestamp
    def distribution(name, value, labels: {})
      prefixed_name = begin
                        if defined?(self::PREFIX)
                          [self::PREFIX, name].join('.')
                        else
                          name
                        end
                      end
      TIMING_SCRIPT.call(prefixed_name, value, labels.to_a.flatten.map(&:to_s))
    end

    def increment(name, labels: {})

      prefixed_name = begin
                        if defined?(self::PREFIX)
                        [self::PREFIX, name].join('.')
                        else
                          name
                        end
                      end
      INCREMENT_CALL.call(prefixed_name, labels.to_a.flatten.map(&:to_s))
    end
  end
end