require 'redis-client'

require 'benchmark'
module RedisClientInstrumentation
  def connect(redis_config)
    res = nil
    took = Benchmark.realtime {res = super}
    puts "Redis connect took #{took * 1000} ms"
    res
  end

  def call(command, redis_config)
    res = nil
    took = Benchmark.realtime { res = super }
    # puts "Redis call took #{took * 1000} ms"
    res
  end

  def call_pipelined(commands, redis_config)
    res = nil
    took = Benchmark.realtime { res = super }
    # puts "Redis call_pipelined took #{took * 1000} ms"
    res
  end
end

module RailsObservatory
  class Engine < ::Rails::Engine
    isolate_namespace RailsObservatory
    config.rails_observatory = ActiveSupport::OrderedOptions.new

    initializer "rails_observatory.assets.precompile" do |app|
      app.config.assets.precompile += %w( rails_observatory/builds/tailwind.css )
    end

    initializer "rails_observatory.redis" do |app|

      redis_config = RedisClient.config(host: "localhost", port: 6379, db: 0, middlewares: [RedisClientInstrumentation])
      $redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))

      puts $redis.call("PING")
    end

    initializer "rails_observatory.instrumentation" do
      ActiveSupport::Notifications.subscribe(/.*/) do |event|
        $redis.call("XADD", "events", "*", "event", event.name, "payload", JSON.generate(event.payload), "duration", event.duration)
      end
    end
  end
end
