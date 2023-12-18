require 'redis-client'

require 'benchmark'
module RedisClientInstrumentation
  def connect(redis_config)
    res = nil
    took = Benchmark.realtime { res = super }
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
    config.rails_observatory = ActiveSupport::OrderedOptions.new

    initializer "rails_observatory.assets.precompile" do |app|
      # app.config.assets.precompile += %w( rails_observatory/builds/tailwind.css )
    end

    initializer "rails_observatory.redis" do |app|


      redis_config = RedisClient.config(host: "localhost", port: 6379, db: 0, middlewares: [RedisClientInstrumentation])
      $redis = redis_config.new_pool(timeout: 0.5, size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)))
      app.config.rails_observatory.redis = $redis
      puts $redis.call("PING")
    end

    initializer "rails_observatory.extend_active_job" do
      ActiveSupport.on_load(:active_job) do |aj|
        aj.prepend(Extension)
      end
    end

    initializer "rails_observatory.logger" do |app|
      Rails.logger.broadcast_to(EventStreamLogger.new)
    end

    initializer "rails_observatory.request_instrumentation" do |app|
      ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |event|
        payload = event.payload.except(:request)
        payload[:request_id] = event.payload[:request].request_id
        payload[:headers] = event.payload[:headers].to_h.keep_if { |k, v| k.start_with?('HTTP_') }
        RequestsStream.add_to_stream(type: event.name, payload:, duration: event.duration)
        ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: event.payload[:request].request_id) if event.payload[:exception_object]
      end
    end

    initializer "rails_observatory.job_instrumentation" do
      ActiveSupport::Notifications.subscribe(/perform.active_job/) do |event|
        job = event.payload[:job]
        payload = event.payload.except(:job, :adapter)
        payload[:job_id] = job.job_id
        payload[:queue_name] = job.queue_name
        payload[:job_class] = job.class.name
        payload[:executions] = job.executions
        payload[:request_id] = job.request_id

        JobsStream.add_to_stream(type: event.name, payload: payload, duration: event.duration)
        ErrorsStream.add_to_stream(event.payload[:exception_object], request_id: job.request_id) if event.payload[:exception_object]
      end
    end
  end
end
