require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.collapse("#{__dir__}/rails_observatory/{events,streams}")
loader.setup # ready!

module RailsObservatory
  # Your code goes here...
end

loader.eager_load