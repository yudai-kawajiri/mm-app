class ContactsController < ApplicationController

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.valid?
      # メール送信処理（後で実装）
      ContactMailer.contact_email(@contact).deliver_now

      redirect_to authenticated_root_path, notice: t('contacts.messages.success_with_response_time')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
