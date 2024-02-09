require_relative './redis_model'
require 'digest'
module RailsObservatory
  class Error < RedisModel

    attribute :time, :float
    attribute :fingerprint, :string
    attribute :has_causes, :boolean, indexed: false
    attribute :causes, compressed: true, indexed: false
    attribute :location, :string
    attribute :class_name, :string
    attribute :message, :string
    attribute :source_extracts, compressed: true, indexed: false
    attribute :trace, compressed: true, indexed: false

    alias_attribute :id, :fingerprint

    attr_accessor :exception

    def exception=(ex)
      ex_wrapper = ActionDispatch::ExceptionWrapper.new(Rails.backtrace_cleaner, ex)
      payload = payload_for_wrapped_exception(ex_wrapper)
      assign_attributes(payload)
      self.has_causes = ex_wrapper.has_cause?
      self.causes = ex_wrapper.wrapped_causes.map { payload_for_wrapped_exception(_1) }
      self.fingerprint = build_fingerprint(ex_wrapper)
    end

    private

    def trace_for_ex(wrapped_ex)
      wrapped_ex.full_trace.each_with_index.map do |trace, idx|
        {
          exception_object_id: wrapped_ex.exception.object_id,
          id: idx,
          trace: trace,
          is_application_trace: wrapped_ex.application_trace.include?(trace),
        }
      end
    end

    def payload_for_wrapped_exception(wrapped_ex)
      {
        class_name: wrapped_ex.exception_class_name,
        message: wrapped_ex.message,
        source_extracts: wrapped_ex.source_extracts,
        trace: trace_for_ex(wrapped_ex),
      }
    end

    def contextual_request_id
      context = ActiveSupport::ExecutionContext.to_h
      context[:controller]&.request&.request_id || context[:job]&.request_id
    end

    def exception_string(wrapped_ex)
      wrapped_ex.exception_class_name + wrapped_ex.exception.backtrace.map { _1.split(":").slice(0..1).join(":") }.join("\n")
    end

    def build_fingerprint(wrapped_ex)
      exceptions = [wrapped_ex]
      exceptions.push(*wrapped_ex.wrapped_causes) if wrapped_ex.has_cause?
      Digest::SHA256.hexdigest(exceptions.map { exception_string(_1) }.join("\n"))
    end

  end
end