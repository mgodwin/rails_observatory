module Observatory
  class MainController < ApplicationController
    def index

      @range = $redis.call("TS.RANGE", "observatory:PostsController:index", "-", "+")
      puts @range.inspect
      puts to_ms_timestamp(1.hour.ago)
      puts to_ms_timestamp(1.minute.ago)
    end

    def to_ms_timestamp(timestamp)
      (timestamp.to_f * 1000).to_i
    end
  end
end
