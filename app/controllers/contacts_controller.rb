class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    Rails.logger.info "===== ContactsController#create ====="
    Rails.logger.info "Contact valid?: #{@contact.valid?}"
    Rails.logger.info "Contact errors: #{@contact.errors.full_messages}"

    if @contact.valid?
      begin
        Rails.logger.info "===== Sending email ====="
        Rails.logger.info "ADMIN_EMAIL: #{ENV.fetch('ADMIN_EMAIL', 'admin@example.com')}"
        Rails.logger.info "MAILER_FROM: #{ENV.fetch('MAILER_FROM', 'noreply@example.com')}"

        mail = ContactMailer.contact_email(@contact)
        Rails.logger.info "Mail To: #{mail.to.inspect}"
        Rails.logger.info "Mail From: #{mail.from.inspect}"
        Rails.logger.info "Mail Subject: #{mail.subject}"
        Rails.logger.info "Mail Reply-To: #{mail.reply_to.inspect}"

        mail.deliver_now

        Rails.logger.info "===== Email sent successfully ====="

        redirect_path = user_signed_in? ? scoped_path(:help_path) : root_path
        redirect_to redirect_path, notice: t("contacts.messages.success_with_response_time")
      rescue => e
        Rails.logger.error "===== Email error: #{e.class} - #{e.message} ====="
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    else
      Rails.logger.info "===== Contact invalid, rendering form ====="
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end

