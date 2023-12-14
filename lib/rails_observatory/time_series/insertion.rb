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
  module TimeSeries::Insertion
    def distribution(name, value, labels: {})
      TIMING_SCRIPT.call(name, value, labels.to_a.flatten.map(&:to_s))
    end

    def increment(name, labels: {})
      INCREMENT_CALL.call(name, labels.to_a.flatten.map(&:to_s))
    end
  end
end