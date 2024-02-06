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

    def call(env)
      start_at = Time.now
      request = ActionDispatch::Request.new(env)

      start_at_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      events, response = EventCollector.instance.collect_events do
        @app.call(env)
      end

      return response if request.params[:controller].blank?

      status, headers, body = response
      body = ::Rack::BodyProxy.new(body) do
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - start_at_mono)
        controller_action = "#{request.params[:controller]}##{request.params[:action]}"
        events_string = JSON.generate(events.map { Serializer.serialize(_1) })
        puts "JSON size #{events_string.bytesize}"
        deflated = nil
        took = Benchmark.realtime { deflated = Zlib.gzip(events_string, level: Zlib::BEST_COMPRESSION) }
        puts "Took #{took} to deflate"
        puts "Deflated size #{deflated.bytesize}"
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
        ).save
        # RequestTrace.redis.call("SET", "rte:#{request.request_id}", deflated)
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
