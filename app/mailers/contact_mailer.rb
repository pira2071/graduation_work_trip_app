class ContactMailer < ApplicationMailer
  default from: ENV["SMTP_USERNAME"]

  def contact_email(contact)
    @contact = contact
    mail(
      to: ENV["TOMAIL"],
      subject: "【TriPlanner】お問い合わせ: #{@contact.subject}"
    )
  end
end
