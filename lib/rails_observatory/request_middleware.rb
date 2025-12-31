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
      exception_raised = nil

      begin
        events, logs = collect_events_and_logs do
          response = @app.call(env)
        end
      rescue Exception => e
        # Extract events from the exception (stored by EventCollector)
        events = e.instance_variable_get(:@_trace_events) || []
        logs = []
        exception_raised = e

        # Capture the error before re-raising
        if request.params[:controller].present?
          controller_action = "#{request.params[:controller]}##{request.params[:action]}"
          capture_error(e, controller_action, start_at)
        end

        raise
      end

      return response if request.params[:controller].blank?

      status, headers, body = response

      # Using Rack::BodyProxy to ensure timing is recorded after the response is fully processed
      body = ::Rack::BodyProxy.new(body) do
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - start_at_mono)
        controller_action = "#{request.params[:controller]}##{request.params[:action]}"

        RailsObservatory.worker_pool.post do
          RequestTrace.create_from_request(request, start_at, duration, status, events:, logs: ).save

          # Capture errors from the request (for caught exceptions that became error responses)
          if (event = events.find { _1.name == 'process_action.action_controller' && _1.payload[:exception_object] })
            capture_error(event.payload[:exception_object], controller_action, start_at)
          end
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

    private

    def capture_error(exception, location, time)
      RailsObservatory.worker_pool.post do
        error = Error.new(exception: exception, location: location, time: time.to_f)
        error.save
        RedisTimeSeries.record_occurrence("error.count", at: time.to_f, labels: { fingerprint: error.fingerprint })
      rescue => e
        Rails.logger.error "Error capturing exception: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
