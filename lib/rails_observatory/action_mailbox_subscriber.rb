module RailsObservatory
  class ActionMailboxSubscriber < ActiveSupport::Subscriber
    attach_to :action_mailbox

    def process(event)
      inbound_email = event.payload[:inbound_email]
      mail = inbound_email.mail

      # Extract mailbox name from the inbound_email
      mailer = inbound_email.class.name

      MailDelivery.new(
        mail: mail.to_s,
        mailer: mailer,
        to: format_addresses(mail.to),
        from: format_addresses(mail.from),
        subject: mail.subject,
        message_id: mail.message_id,
        time: Time.now.to_f,
        duration: event.duration,
        direction: "inbound"
      ).save

      RedisTimeSeries.record_occurrence("mailer.inbound_count", labels: {mailer: mailer})
    end

    private

    def format_addresses(addresses)
      return nil if addresses.nil?
      Array(addresses).join(", ")
    end
  end
end
