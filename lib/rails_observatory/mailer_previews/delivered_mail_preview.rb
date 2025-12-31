# Exposes a preview of delivered emails stored by RailsObservatory.
class DeliveredMailPreview < ActionMailer::Preview

  def preview
    mail_delivery = RailsObservatory::MailDelivery.find(params[:message_id])
    Mail.new(mail_delivery.mail)
  end

end
