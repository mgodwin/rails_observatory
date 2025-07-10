require 'rails_observatory/engine'
require 'rails_observatory/server'
module RailsObservatory
  mattr_accessor :importmap, default: Importmap::Map.new

  module_function def worker_pool
    @server ||= Concurrent::ThreadPoolExecutor.new(
      name: "RailsObservatory",
      min_threads: 1,
      max_threads: 4,
      max_queue: 0,
      )
  end


  module_function def record_occurrence(...)
    TimeSeries.record_occurrence(...)
  end

  module_function def record_timing(...)
    TimeSeries.record_timing(...)
  end

end