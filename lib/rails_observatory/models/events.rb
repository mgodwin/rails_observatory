module RailsObservatory
  module Events
    extend ActiveSupport::Concern

    included do
      attribute :events, indexed: false, compressed: true

      def events
        attr_value = super
        return nil if attr_value.nil?

        EventCollection.new(attr_value)
      end
    end

    def mail_events
      events.only("enqueue.action_job", "deliver.action_mailer")
        .reject { it["name"] == "enqueue.action_job" && it.dig("payload", "job", "class") != "ActionMailer::MailDeliveryJob" }
    end

    def job_events
      events.only("enqueue.active_job")
        .reject { it.dig("payload", "job", "class") == "ActionMailer::MailDeliveryJob" }
    end

    def has_errors?
      events.any? { it.dig("payload", "exception") }
    end
  end
end
