require 'rails_observatory/engine'
module RailsObservatory

  def redis
    $redis
  end
end