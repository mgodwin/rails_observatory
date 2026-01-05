class ScenariosMailer < ApplicationMailer
  def welcome(user_email:)
    @user_email = user_email
    mail(to: user_email, subject: "Welcome to our platform!")
  end

  def notification(user_email:, message:)
    @user_email = user_email
    @message = message
    mail(to: user_email, subject: "Notification: #{message.truncate(30)}")
  end

  def newsletter(recipients:)
    @recipients = Array(recipients)
    mail(to: recipients, subject: "Monthly Newsletter - #{Date.current.strftime("%B %Y")}")
  end
end
