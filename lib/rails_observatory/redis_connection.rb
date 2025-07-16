module RailsObservatory
  module RedisConnection
    extend ActiveSupport::Concern

    class_methods do
      def redis
        Rails.configuration.rails_observatory.redis
      end
    end

    def redis
      self.class.redis
    end
  end
end