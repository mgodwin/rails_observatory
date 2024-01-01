module RailsObservatory
  module ActionMailer
    class ProcessEvent < StreamEvent

      def action
        payload[:action]
      end

      def mailer
        payload[:mailer]
      end

      def failed?
        payload[:failed]
      end
      def labels
        { mailer_action: "#{mailer}##{action}" }
      end

      def process
        MailerTimeSeries.increment("count", labels: )
        MailerTimeSeries.increment("error_count", labels: ) if failed?
        MailerTimeSeries.distribution("latency", duration, labels: )
      end
    end
  end
end