module RailsObservatory
  class MetricsController < ApplicationController

    def index

      @starting_metrics = RedisTimeSeries.query_index(true)

    end

    def autocomplete
      render json: RedisTimeSeries.query_index(true).where(compaction: %w[sum avg]).map(&:name)
    end

    def query_range

    end
  end

end