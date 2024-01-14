require 'redis-client'

require 'benchmark'
require_relative './subscribers/action_controller_subscriber'
require_relative './redis/request_event_set'
require_relative './patches/notification_event'
module RedisClientInstrumentation
  def connect(redis_config)
    res = nil
    took = Benchmark.realtime { res = super }
    puts "Redis connect took #{took * 1000} ms"
    res
  end

  def call(command, redis_config)
    res = nil
    # puts "Thread #{Thread.current.object_id} Redis call #{command.first} #{command[1..-1].join(" ")}"
    state = ActiveSupport::ExecutionContext.to_h[:rails_observatory_redis] || 0
    took = Benchmark.realtime { res = super }
    ActiveSupport::ExecutionContext[:rails_observatory_redis] = took + state
    res
  end

  def call_pipelined(commands, redis_config)
    res = nil
    took = Benchmark.realtime { res = super }
    # puts "Redis call_pipelined took #{took * 1000} ms"
    res
  end
end

def noisy_subscriber(name)
  ActiveSupport::Notifications.subscribe(name) do |*args|
    begin
      yield ActiveSupport::Notifications::Event.new(*args)
    rescue => e
      puts "INSTRUMENTATION ERROR: #{args[0]} #{e} (subscriber: #{name})"
      puts e.backtrace.first(2).join("\n")
    end
  end
end

module Extension

  attr_accessor :request_id

  def serialize
    hash = super
    if ActiveSupport::ExecutionContext.to_h[:controller]&.request
      hash["request_id"] = ActiveSupport::ExecutionContext.to_h[:controller]&.request&.request_id
    end
    hash
  end

  def deserialize(job_data)
    super(job_data)
    self.request_id = job_data['request_id']
  end
end

module RailsObservatory
  class Engine < ::Rails::Engine
    isolate_namespace RailsObservatory
    config.eager_load_paths += paths["lib"].to_a

    middleware.use(Rack::Static, urls: ["/assets"], root: config.root.join("public"))

    config.rails_observatory = ActiveSupport::OrderedOptions.new
    config.rails_observatory.streams = [:requests]

    initializer "rails_observatory.redis" do |app|
      redis_config = RedisClient.config(host: "localhost", port: 6379, db: 0, middlewares: [RedisClientInstrumentation])
      $redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))
      app.config.rails_observatory.redis = $redis
    end

    initializer "rails_observatory.extend_active_job" do
      ActiveSupport.on_load(:active_job) do |aj|
        aj.prepend(Extension)
      end

      ActiveSupport.on_load(:action_controller) do |am|
        require_relative './railties/redis_runtime'
        am.include Railties::RedisRuntime
      end
    end

    initializer "rails_observatory.logger" do |app|
      # require_relative './event_stream_logger'
      # Rails.logger.broadcast_to(EventStreamLogger.new)
    end

    initializer "rails_observatory.request_instrumentation" do |app|
      # noisy_subscriber(/process_action.action_controller/) do |event|
      #
      #   RequestsStream.add_to_stream(type: event.name, payload:, duration: event.duration)
      #   ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: event.payload[:request].request_id) if event.payload[:exception_object]
      # end
      # require_relative './streams/requests_stream'
      # require_relative './streams/errors_stream'

      ActiveSupport::Notifications.monotonic_subscribe(/^[^!].*/) do |event|
        request_id = event.payload[:request_id]
        request_id ||= ActiveSupport::ExecutionContext.to_h[:controller]&.request&.request_id

        if request_id
          RequestEventSet.new(request_id).add(event)
        end
        # payload = event.payload
        # payload[:failed] = payload[:exception_object].present?
        # payload[:request_id] ||= ActiveSupport::ExecutionContext.to_h[:controller]&.request&.request_id


        # ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: event.payload[:request_id]) if event.payload[:exception_object]
        # RequestsStream.add_to_stream(event)
      end
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

    initializer "rails_observatory.job_instrumentation" do
      # noisy_subscriber(/perform.active_job/) do |event|
      #   job = event.payload[:job]
      #   payload = event.payload.except(:job, :adapter)
      #   payload[:job_id] = job.job_id
      #   payload[:queue_name] = job.queue_name
      #   payload[:job_class] = job.class.name
      #   payload[:executions] = job.executions
      #   payload[:request_id] = job.request_id
      #   # TODO: This needs to be done in the start event so the perform time doesn't skew the time later
      #   payload[:queue_duration] = event.time - job.enqueued_at.to_f if job.enqueued_at
      #   payload[:failed] = payload[:exception_object].present?
      #
      #   JobsStream.add_to_stream(type: event.name, payload: payload, duration: event.duration)
      #   ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: job.request_id) if event.payload[:exception_object]
      # end
    end
  end
end
