module RedisClientInstrumentation

  def call(command, redis_config)
    res = nil
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
