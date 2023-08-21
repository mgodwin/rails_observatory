require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module RailsObservatory
  # Your code goes here...
end

loader.eager_load