module RailsObservatory
  class ErrorsController < ApplicationController
    layout "rails_observatory/application_time_slice"

    def index
      Error.ensure_index
      @errors = Error.all.to_a

      # Get counts grouped by fingerprint
      fingerprints = @errors.map(&:fingerprint)

      if fingerprints.any?
        @count_by_fingerprint = RedisTimeSeries
          .query_value("error.count", :sum)
          .where(fingerprint: true)
          .group("fingerprint")
          .to_a
          .index_by { it.labels["fingerprint"] }
          .transform_values(&:value)

        # Get sparkline data for each error (12 bins)
        @series_by_fingerprint = RedisTimeSeries
          .query_range("error.count", :sum)
          .where(fingerprint: true)
          .group("fingerprint")
          .bins(calculate_bin_duration(12))
          .to_a
          .index_by { it.labels["fingerprint"] }
      else
        @count_by_fingerprint = {}
        @series_by_fingerprint = {}
      end
    end

    def show
      @error = Error.find(params[:id])

      # Get total count for this error
      count_result = RedisTimeSeries
        .query_value("error.count", :sum)
        .where(fingerprint: @error.fingerprint)
        .to_a
        .first

      @count = count_result&.value || 0

      # Get sparkline data for different time periods
      @past_24_hours = query_sparkline(@error.fingerprint, 24.hours.ago, 24)
      @past_7_days = query_sparkline(@error.fingerprint, 7.days.ago, 24)
      @past_30_days = query_sparkline(@error.fingerprint, 30.days.ago, 24)
    end

    private

    def calculate_bin_duration(target_bins)
      slice = ActiveSupport::IsolatedExecutionState[:observatory_slice]
      return 60_000 unless slice # Default to 1 minute bins

      from_time = slice.begin || 1.hour.ago
      to_time = slice.end || Time.now
      duration_ms = ((to_time.to_i - from_time.to_i) * 1000 / target_bins).to_i
      [duration_ms, 1000].max # Minimum 1 second bins
    end

    def query_sparkline(fingerprint, from_time, bins)
      to_time = Time.now
      duration_ms = ((to_time.to_i - from_time.to_i) * 1000 / bins).to_i
      duration_ms = [duration_ms, 1000].max

      RedisTimeSeries
        .query_range("error.count", :sum, from: from_time, to: to_time)
        .where(fingerprint: fingerprint)
        .bins(duration_ms)
        .to_a
        .first
    end
  end
end
