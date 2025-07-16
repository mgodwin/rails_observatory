# frozen_string_literal: true

# require "active_support/notifications"
require 'zlib'

module RailsObservatory
  class RequestMiddleware

    def initialize(app)
      @app = app
    end

    def collect_events_and_logs
      logs = []
      events = EventCollector.collect_events do
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



      # if (event = events.find { _1.name == 'process_action.action_controller' && _1.payload[:exception_object] })
      #   error = Error.new(exception: event.payload[:exception_object], location: controller_action, time: Time.now)
      #   error.save
      #   TimeSeries.record_occurrence("error.count", labels: { fingerprint: error.fingerprint })
      # end

      return response if request.params[:controller].blank? # || request.params[:controller] =~ /rails_observatory/

      status, headers, body = response

      # Using Rack::BodyProxy to ensure timing is recorded after the response is fully processed
      body = ::Rack::BodyProxy.new(body) do

        # TimeSeries.record_occurrence("request.count", labels:)
        # TimeSeries.record_occurrence("request.error_count", labels:) if status >= 500

        # serialized_events = events.map { Serializer.serialize(_1) }
        # EventCollection.new(serialized_events).self_time_by_library.each do |library, self_time|
        #   TimeSeries.record_timing("request.latency/#{library}", self_time, labels: { action: controller_action })
        # end
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - start_at_mono)

        RailsObservatory.worker_pool.post do
          RequestTrace.create_from_request(request, start_at, duration, status, events:, logs: ).save
        rescue => e
          puts "Error saving request trace: #{e.message}"
          puts e.backtrace.join("\n")
        end
      rescue => e
        puts e
        puts e.backtrace.join("\n")
      end

      [status, headers, body]
    end
  end
end
