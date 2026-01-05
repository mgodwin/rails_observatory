require "redis-client"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

module RailsObservatory
  # This patch exists to reduce the call stack depth when instrumenting middleware calls.
  module PatchInstrumentationProxy
    def call(env)
      result = nil
      handle = ActiveSupport::Notifications.instrumenter.build_handle(ActionDispatch::MiddlewareStack::InstrumentationProxy::EVENT_NAME, @payload)
      handle.start
      begin
        result = @middleware.call(env)
      rescue Exception => e # standard:disable Lint/RescueException
        @payload[:exception] = [e.class.name, e.message]
        @payload[:exception_object] = e
        raise e
      ensure
        handle.finish
      end
      result
    end
  end

  class Engine < ::Rails::Engine
    isolate_namespace RailsObservatory

    # This middleware is specific to the engine and will not be included in the application stack
    # middleware.use(Rack::Static, urls: ["/assets"], root: config.root.join("public"))

    config.rails_observatory = ActiveSupport::OrderedOptions.new
    config.rails_observatory.redis = {host: "localhost", port: 6379, db: 0, pool_size: ENV["RAILS_MAX_THREADS"] || 3}

    initializer "rails_observatory.redis" do |app|
      app.config.rails_observatory.redis => pool_size:, **redis_config
      redis_config = RedisClient.config(**redis_config.merge(middlewares: [RedisClientInstrumentation]))
      app.config.rails_observatory.redis = redis_config.new_pool(timeout: 0.5, size: pool_size)
    end

    initializer "rails_observatory.middleware" do |app|
      # Application middleware is not instrumented UNLESS there's an ActiveSupport::Notification subscriber listening.
      # By instantiating the collector, we register a subscriber and ensure that the InstrumentationProxy is used in
      # our application middleware stack.
      EventCollector.start

      # puts app.middleware.inspect

      # Add the RailsObservatory middleware to the top of the application middleware stack
      app.middleware.unshift(RequestMiddleware)

      ActionDispatch::MiddlewareStack::InstrumentationProxy.prepend(PatchInstrumentationProxy)
    end

    initializer "rails_observatory.active_job_instrumentation" do
      ActiveSupport.on_load(:active_job) do |active_job|
        active_job.include(Railties::ActiveJobInstrumentation)
      end
    end

    initializer "rails_observatory.worker_pool" do |app|
    end

    initializer "rails_observatory.logger" do |app|
      Rails.logger.broadcast_to(LogCollector.new)
    end

    initializer "rails_observatory.mailer_instrumentation" do |app|
      config.action_mailer.preview_paths << "#{config.root}/lib/rails_observatory/mailer_previews"
    end

    initializer "rails_observatory.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/javascript")
      app.config.assets.paths << root.join("app/assets/images")
      app.config.assets.precompile += %w[rails_observatory_manifest]
    end

    initializer "rails_observatory.importmap", after: "importmap" do |app|
      RailsObservatory.importmap.draw(root.join("config/importmap.rb"))
      if app.config.importmap.sweep_cache && app.config.reloading_enabled?
        RailsObservatory.importmap.cache_sweeper(watches: root.join("app/javascript"))

        ActiveSupport.on_load(:action_controller_base) do
          before_action { RailsObservatory.importmap.cache_sweeper.execute_if_updated }
        end
      end
    end
  end
end
