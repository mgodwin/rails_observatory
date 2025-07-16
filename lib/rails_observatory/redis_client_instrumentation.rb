module RailsObservatory
  module RedisClientInstrumentation
    def call(command, redis_config)
      payload_command = command
      payload_command = [payload_command.first] if payload_command.first == "SCRIPT"
      ActiveSupport::Notifications.instrument("call.redis", { command: payload_command.join(' ') }) do
        super
      end
    end

    def call_pipelined(commands, redis_config)
      res = nil
      took = Benchmark.realtime { res = super }
      # puts "Redis call_pipelined took #{took * 1000} ms"
      res
    end
  end
end