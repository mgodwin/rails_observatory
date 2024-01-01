module RailsObservatory
  class ErrorsStream < Redis::Stream

    def self.add_to_stream(exception, **payload)
      ex_wrapper = ActionDispatch::ExceptionWrapper.new(Rails.backtrace_cleaner, exception)
      payload = payload_for_wrapped_exception(ex_wrapper)
      payload[:request_id] = contextual_request_id
      payload[:location] = contextual_location
      payload[:has_causes] = !!ex_wrapper.has_cause?
      payload[:causes] = ex_wrapper.wrapped_causes.map { payload_for_wrapped_exception(_1) }
      payload[:fingerprint] = build_fingerprint(ex_wrapper)
      super(type: 'error', payload: payload, duration: 0)
    end

    def self.payload_for_wrapped_exception(wrapped_ex)
      {
        class_name: wrapped_ex.exception_class_name,
        message: wrapped_ex.message,
        source_extracts: wrapped_ex.source_extracts,
        trace: trace_for_ex(wrapped_ex),
      }
    end


    def self.trace_for_ex(wrapped_ex)
      wrapped_ex.full_trace.each_with_index.map do |trace, idx|
        {
          exception_object_id: wrapped_ex.exception.object_id,
          id: idx,
          trace: trace,
          is_application_trace: wrapped_ex.application_trace.include?(trace),
        }
      end
    end
    def self.build_fingerprint(wrapped_ex)
      exceptions = [wrapped_ex]
      exceptions.push(*wrapped_ex.wrapped_causes) if wrapped_ex.has_cause?
      Digest::MD5.hexdigest(exceptions.map { exception_string(_1) }.join("\n"))
    end

    def self.exception_string(wrapped_ex)
      wrapped_ex.exception_class_name + wrapped_ex.exception.backtrace.map { _1.split(":").slice(0..1).join(":") }.join("\n")
    end

    def self.contextual_request_id
      context = ActiveSupport::ExecutionContext.to_h
      context[:controller]&.request&.request_id || context[:job]&.request_id
    end

    def self.contextual_location
      context = ActiveSupport::ExecutionContext.to_h
      controller = context[:controller]
      job = context[:job]

      if controller
        controller.request.parameters['controller'] + "#" + controller.request.parameters['action']
      elsif job
        job.class.name
      else
        nil
      end
    end
  end
end