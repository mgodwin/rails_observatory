require 'redis-client'
module RailsObservatory
  class Engine < ::Rails::Engine
    isolate_namespace RailsObservatory

    initializer "rails_observatory.assets.precompile" do |app|
      app.config.assets.precompile += %w( rails_observatory/builds/tailwind.css )
    end

    initializer "rails_observatory.redis" do |app|
      puts "Setting up redis"
      redis_config = RedisClient.config(host: "localhost", port: 6379, db: 0)
      $redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))

      puts $redis.call("PING")
    end

    initializer "rails_observatory.instrumentation" do

    end
  end
end
