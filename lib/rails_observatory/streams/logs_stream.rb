require_relative '../redis/stream'
module RailsObservatory
  class LogsStream < Redis::Stream
  end
end