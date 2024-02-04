require 'redis-client'

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
      # require_relative './event_stream_logger'
      # Rails.logger.broadcast_to(EventStreamLogger.new)
    end


    initializer "rails_observatory.mailer_instrumentation" do |app|
      # noisy_subscriber(/deliver.action_mailer/) do |event|
      #   payload = event.payload.except(:mail)
      #
      #   context = ActiveSupport::ExecutionContext.to_h
      #   payload[:request_id] = context[:controller]&.request&.request_id || context[:job]&.request_id
      #   payload[:job_id] = context[:job]&.job_id
      #   payload[:failed] = payload[:exception_object].present?
      #   payload[:mail] = event.payload[:mail].to_s
      #
      #   MailersStream.add_to_stream(type: event.name, payload: payload, duration: event.duration)
      #   ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: payload[:request_id]) if event.payload[:exception_object]
      # end

      # noisy_subscriber(/process.action_mailer/) do |event|
      #   payload = event.payload
      #   context = ActiveSupport::ExecutionContext.to_h
      #   payload[:request_id] = context[:controller]&.request&.request_id || context[:job]&.request_id
      #   payload[:job_id] = context[:job]&.job_id
      #   payload[:failed] = payload[:exception_object].present?
      #   MailersStream.add_to_stream(type: event.name, payload: payload, duration: event.duration)
      #   ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: payload[:request_id]) if event.payload[:exception_object]
      # end
    end
  end
end
