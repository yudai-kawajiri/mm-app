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
      Rails.logger.info "===== Sending email ====="
      
      begin
        ContactMailer.contact_email(@contact).deliver_now
        Rails.logger.info "===== Email sent successfully ====="
      rescue => e
        Rails.logger.error "===== Email error: #{e.class} - #{e.message} ====="
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end

      redirect_path = user_signed_in? ? scoped_path(:help_path) : root_path
      redirect_to redirect_path, notice: t("contacts.messages.success_with_response_time")
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
