require_relative '../redis/stream'
module RailsObservatory
  class RequestsStream < Redis::Stream
  end
end