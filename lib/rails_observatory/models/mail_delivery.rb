module RailsObservatory
  class MailDelivery < RedisModel
    attribute :message_id, :string
    attribute :time, :float
    attribute :duration, :float
    attribute :mailer, :string
    attribute :to, :string
    attribute :from, :string
    attribute :subject, :string
    attribute :mail, compressed: true, indexed: false

    alias_attribute :id, :message_id

    def to=(val)
      if val.is_a?(Array)
        super(val.join(", "))
      else
        super
      end
    end

    def from=(val)
      if val.is_a?(Array)
        super(val.join(", "))
      else
        super
      end
    end
  end
end
