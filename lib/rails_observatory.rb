require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_observatory/{events,streams}")
loader.setup # ready!

module RailsObservatory

  def redis
    $redis
  end
end

loader.eager_load