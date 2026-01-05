module RailsObservatory
  module Railties
    module RedisRuntime
      def append_info_to_payload(payload)
        super

        payload[:rails_observatory_runtime] = ActiveSupport::ExecutionContext.to_h[:rails_observatory_redis]
      end
    end
  end
end
