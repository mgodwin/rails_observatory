module RailsObservatory
  class ActionMailerSubscriber < ActiveSupport::Subscriber
    attach_to :action_mailer

    def deliver(event)
      event.payload => {mail:, mailer:, to:, from:, subject:, message_id:}
      MailDelivery.new(mail:, mailer:, to:, from:, subject:, message_id:, time: Time.now.to_f, duration: event.duration).save

      RedisTimeSeries.record_occurrence("mailer.delivery_count", labels: { mailer:})
    end

  end
end