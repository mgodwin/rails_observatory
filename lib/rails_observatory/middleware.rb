# frozen_string_literal: true

require "active_support/notifications"
require_relative './event_collector'
require_relative './models/request_trace'
require_relative './serializers/serializer'
require 'zlib'
require 'benchmark'

module RailsObservatory
  class Middleware

    def initialize(app)
      @app = app
    end

    def collect_events_and_logs
      logs = []
      events = EventCollector.instance.collect_events do
        logs = LogCollector.collect_logs do
          yield
        end
      end
      [events, logs]
    end

    def call(env)
      start_at = Time.now
      request = ActionDispatch::Request.new(env)

      start_at_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      response = nil
      events, logs = collect_events_and_logs do
        response = @app.call(env)
      end

      return response if request.params[:controller].blank?

      status, headers, body = response
      body = ::Rack::BodyProxy.new(body) do
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - start_at_mono)
        controller_action = "#{request.params[:controller]}##{request.params[:action]}"
        RequestTrace.new(
          request_id: request.request_id,
          status:,
          http_method: request.method,
          route_pattern: request.route_uri_pattern,
          action: controller_action,
          error: events.any? { _1.payload[:exception] },
          format: request.format,
          duration:,
          time: start_at.to_f,
          path: request.path,
          events: events.map { Serializer.serialize(_1) },
          logs:
        ).save
        labels = { action: controller_action, format: request.format, status:, http_method: request.method }
        TimeSeries.record_occurrence("request.count", labels:)
        TimeSeries.record_occurrence("request.error_count", labels:) if status >= 500
        TimeSeries.record_timing("request.latency", duration, labels:)
      rescue => e
        puts e
        puts e.backtrace.join("\n")
      end

      [status, headers, body]
    end
  end
end
