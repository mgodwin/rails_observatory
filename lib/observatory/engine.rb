require 'redis-client'
module Observatory
  class Engine < ::Rails::Engine
    isolate_namespace Observatory

    initializer "observatory.assets.precompile" do |app|
      app.config.assets.precompile += %w( observatory/application.css )
    end

    initializer "observatory.redis" do |app|
      puts "Setting up redis"
      redis_config = RedisClient.config(host: "localhost", port: 6379, db: 0)
      $redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))

      puts $redis.call("PING")
    end

    initializer "observatory.instrumentation" do
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |event|
        puts "we did it!"
        puts event.duration

        key = "observatory:#{event.payload[:controller]}:#{event.payload[:action]}"
        # Check if key exists
        puts "key: #{key}"
        unless $redis.call("EXISTS", key) > 0
          puts "Creating REDIS timeseries"
          puts $redis.call("TS.CREATE", key, "RETENTION", 15.minutes.to_i * 1000, "LABELS", "controller", event.payload[:controller], "action", event.payload[:action], "format", event.payload[:format], "status", event.payload[:status], "method", event.payload[:method])
        end
        puts "Adding datapoint"
        puts $redis.call("TS.ADD", key, "*", event.duration)
      end
    end
  end
end
