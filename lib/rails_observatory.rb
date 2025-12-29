require 'importmap-rails'
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.push_dir("#{__dir__}/rails_observatory/models", namespace: RailsObservatory)
loader.push_dir("#{__dir__}/rails_observatory/mailer_previews")
loader.push_dir("#{__dir__}/rails_observatory/serializers", namespace: RailsObservatory)
loader.setup
loader.eager_load

module RailsObservatory
  mattr_accessor :importmap, default: Importmap::Map.new

  module_function def worker_pool
    @server ||= if Rails.env.test?
      Concurrent::ImmediateExecutor.new
    else
      Concurrent::ThreadPoolExecutor.new(
        name: "RailsObservatory",
        min_threads: 1,
        max_threads: 4,
        max_queue: 0,
      )
    end
  end


  module_function def record_occurrence(...)
    RedisTimeSeries.record_occurrence(...)
  end

  module_function def record_timing(...)
    RedisTimeSeries.record_timing(...)
  end

end