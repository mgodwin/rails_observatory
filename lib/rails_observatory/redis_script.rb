module RailsObservatory

  # A handy wrapper for loading and running Redis Lua scripts.
  # Scripts are loaded based on the class name, so each subclass should have a corresponding Lua script file.
  # When calling the script, it will first try to use the cached SHA1 of the script.
  # If the script is not found in Redis, it will load the script from the file system and cache its SHA1 for future calls.
  class RedisScript
    def self.script
      @script ||= begin
                    script_path = File.join(File.dirname(__FILE__), "redis_scripts", "#{self.name.demodulize.underscore}.lua")
                    File.read(script_path)
                  end
    end

    def self.redis
      Rails.configuration.rails_observatory.redis
    end

    def self.call(...)
      @sha1 ||= redis.call('SCRIPT', 'LOAD', script)
      redis.call("EVALSHA", @sha1, 0, ...)
    rescue => e
      if e.message =~ /NOSCRIPT/
        @sha1 = redis.call('SCRIPT', 'LOAD', script)
        retry
      else
        raise e
      end
    end

  end

end