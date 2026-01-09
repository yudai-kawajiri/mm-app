class ContactMailer < ApplicationMailer
  def contact_email(contact)
    @contact = contact

    # 管理者に送信
    mail(
      from: ENV.fetch("MAILER_FROM"),
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.com"),
      subject: I18n.t("contact_mailer.subject", subject: @contact.subject),
      reply_to: @contact.email
    )
  end
end
