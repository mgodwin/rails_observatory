module RailsObservatory
  class MailerTimeSeries < Redis::TimeSeries

    PREFIX = "mailer"

    def mailer_action
      labels[:mailer_action]
    end

    def self.where(name: nil, mailer_action: nil)
      super(name:, mailer_action:)
    end
  end
end