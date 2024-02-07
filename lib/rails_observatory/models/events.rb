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
      events.only('enqueue.action_job', 'deliver.action_mailer')
            .reject { _1['name'] == 'enqueue.action_job' && _1.dig('payload', 'job', 'class') != 'ActionMailer::MailDeliveryJob' }
    end
  end
end