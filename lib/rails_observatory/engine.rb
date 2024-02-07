require 'redis-client'

require_relative './action_mailer_subscriber'
module RailsObservatory
  class Engine < ::Rails::Engine
    isolate_namespace RailsObservatory

    # This middleware is specific to the engine and will not be included in the application stack
    middleware.use(Rack::Static, urls: ["/assets"], root: config.root.join("public"))

    config.rails_observatory = ActiveSupport::OrderedOptions.new
    config.rails_observatory.redis = {}

    initializer "rails_observatory.redis" do |app|
      require_relative './redis/logging_middleware'
      require_relative './redis/redis_client_instrumentation'
      app.config.rails_observatory.redis => pool_size:, **redis_config
      #.merge(middlewares: [LoggingMiddleware])
      redis_config = RedisClient.config(**redis_config.merge(middlewares: [RedisClientInstrumentation]))
      $redis = redis_config.new_pool(timeout: 0.5, size: pool_size)
      app.config.rails_observatory.redis = $redis
    end

    initializer "rails_observatory.middleware" do |app|
      require_relative './middleware'

      # Middleware is not instrumented UNLESS there's a subscriber listening.
      # By instantiating the collector, we ensure that the InstrumentationProxy is used
      EventCollector.instance

      app.middleware.insert_before(ActionDispatch::HostAuthorization, Middleware)
    end

    initializer "rails_observatory.active_job_instrumentation" do
      require_relative './models/job_trace'
      ActiveSupport.on_load(:active_job) do |active_job|
        require_relative './railties/active_job_instrumentation'
        active_job.include(Railties::ActiveJobInstrumentation)
      end
    end

    initializer "rails_observatory.logger" do |app|
      require_relative './log_collector'
      Rails.logger.broadcast_to(LogCollector.new)
    end


    initializer "rails_observatory.mailer_instrumentation" do |app|
      config.action_mailer.preview_paths << "#{config.root}/lib/rails_observatory/mailer_previews"
    end
  end
end
