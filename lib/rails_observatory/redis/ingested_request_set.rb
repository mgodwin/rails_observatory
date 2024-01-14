require_relative './sorted_set'
require_relative '../request'
module RailsObservatory
  class IngestedRequestSet < SortedSet
    def initialize
      @name = "requests"
    end

    def add(request)
      redis.call('ZADD', @name, request.rel_start, request.request_id)
    end

    def all
      LimitOffsetEnumerator.new(self) do |request_id|
        Request.find(request_id)
      end
    end
  end
end

