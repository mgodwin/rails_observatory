require 'rails_observatory/engine'
module RailsObservatory
  mattr_accessor :importmap, default: Importmap::Map.new
end