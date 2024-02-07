# Preview all emails at http://localhost:3000/rails/mailers/new_user_mailer
class DeliveredMailPreview < ActionMailer::Preview

  def preview
    mail_delivery = RailsObservatory::MailDelivery.find(params[:message_id])
    Mail.new(mail_delivery.mail)
  end

end
