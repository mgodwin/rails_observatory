# frozen_string_literal: true

require "active_support/notifications"
require_relative './event_collector'
require_relative './models/request_trace'
require_relative './serializers/serializer'

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
        puts "Saving request"
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - start_at_mono)
        RequestTrace.new(
          request_id: request.request_id,
          status:,
          http_method: request.method,
          action: "#{request.params[:controller]}##{request.params[:action]}",
          error: events.any? { _1.payload[:exception] },
          duration:,
          time: start_at.to_f,
          path: request.path,
          events: events.map { EventSerializer.serialize_event(_1) }
        ).save
      end

      [status, headers, body]
    end
  end
end
