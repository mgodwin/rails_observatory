module RailsObservatory
  class MainController < ApplicationController
    def index
      time_frame = (1.hour.ago..)
      @all_series = TimeSeries.where(name: 'process_action.action_controller.count', action: '*')
      puts @all_series.inspect
      @all_series = @all_series.select do |series|
        series.last_timestamp > time_frame.begin.to_i
      end
      # @request_count_range = TimeSeries.where(name: "process_action.action_controller.count", action: nil).first[time_frame].rollup(buckets: 80)
      # @latency_range = TimeSeries.where(name:"process_action.action_controller.count", action:nil).first[time_frame].rollup(buckets: 120)
    end
  end
end
