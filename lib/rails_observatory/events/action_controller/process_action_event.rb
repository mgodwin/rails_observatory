module RailsObservatory
  module ActionController
    class ProcessActionEvent
      include ActiveModel::Attributes
      include ActiveModel::Serializers::JSON


      attribute :duration
      attribute :db_runtime
      attribute :view_runtime
      attribute :status
      attribute :controller
      attribute :action
      attribute :request_format
      attribute :request_method


      def self.from_event(event)

      end

      def duration
        payload[:duration]
      end
      def db_runtime
        payload[:db_runtime] || 0
      end

      def view_runtime
        payload[:view_runtime] || 0
      end

      def status
        payload[:status]
      end

      def controller
        payload[:controller]
      end

      def action
        payload[:action]
      end

      def request_format
        payload[:format]
      end

      def request_method
        payload[:method]
      end

      def controller_action
        "#{controller.underscore}##{action}"
      end


    end
  end
end