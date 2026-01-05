module RailsObservatory
  class MetricsController < ApplicationController
    layout "rails_observatory/application_time_slice"

    def index
      @all_series = begin
        RedisTimeSeries.query_index(true).to_a
      rescue RedisClient::CommandError
        []
      end

      # Summary stats
      @unique_metric_names = @all_series.map(&:name).uniq.sort
      @total_series_count = @all_series.size
      @counter_names = @all_series
        .select { |s| s.labels["compaction"] == "sum" }
        .map(&:name)
        .uniq
      @distribution_names = @all_series
        .select { |s| %w[avg min max].include?(s.labels["compaction"]) }
        .map(&:name)
        .uniq

      # Selected metric from URL params
      @selected_metric = params[:metric]

      if @selected_metric.present?
        # Get series for selected metric
        @metric_series = @all_series.select { |s| s.name == @selected_metric }
        @available_labels = extract_available_labels(@metric_series)
        @available_compactions = @metric_series.map { |s| s.labels["compaction"] }.uniq.sort

        # Determine metric type and set defaults
        @is_counter = @available_compactions == ["sum"]
        @compaction = params[:compaction].presence || (@is_counter ? "sum" : "avg")
        @chart_type = params[:chart_type].presence || (@is_counter ? "bar" : "area")
        @group_by = params[:group_by].presence

        # Build chart data using metric_series spec format
        @chart_data = build_chart_data
      end
    end

    def autocomplete
      names = begin
        RedisTimeSeries.query_index(true)
          .where(compaction: %w[sum avg])
          .map(&:name)
          .uniq
          .sort
      rescue RedisClient::CommandError
        []
      end
      render json: names
    end

    def labels
      metric_name = params[:name]
      series = begin
        RedisTimeSeries.query_index(true)
          .select { |s| s.name == metric_name }
      rescue RedisClient::CommandError
        []
      end
      labels = extract_available_labels(series)
      render json: labels
    end

    private

    def extract_available_labels(series)
      reserved_labels = %w[name compaction __source__]
      series
        .flat_map { |s| s.labels.keys }
        .uniq
        .reject { |k| reserved_labels.include?(k) }
        .sort
    end

    def build_chart_data
      spec = "#{@selected_metric}|#{@compaction}->60@#{@compaction}"
      spec = "#{spec} (#{@group_by})" if @group_by.present?

      slice = ActiveSupport::IsolatedExecutionState[:observatory_slice]
      query = RedisTimeSeries.query_range_by_string(spec, from: slice&.begin, to: slice&.end)
      group_label = query.group_label.to_s
      query.to_a.map { |s| {name: s.labels[group_label], data: s.filled_data} }
    end
  end
end
