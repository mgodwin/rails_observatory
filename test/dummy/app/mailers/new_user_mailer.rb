class NewUserMailer < ApplicationMailer

  def greeting
    mail(to: "hello@example.com", subject: "Hello")
  end
end
