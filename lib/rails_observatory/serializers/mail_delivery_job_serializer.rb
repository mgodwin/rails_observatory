module RailsObservatory
  class MailDeliveryJobSerializer < JobSerializer
    def serialize(job)
      super.merge(
        mailer_class: job.arguments.first,
        mailer_method: job.arguments.second
      )
    end

    def self.klass
      ActionMailer::MailDeliveryJob
    end
  end
end