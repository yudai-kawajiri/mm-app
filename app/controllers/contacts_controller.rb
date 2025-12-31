class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.valid?
      # メール送信処理
      ContactMailer.contact_email(@contact).deliver_now

      # ログイン状態に応じてリダイレクト先を変更
      redirect_path = user_signed_in? ? scoped_path(:help_path) : root_path
      redirect_to redirect_path, notice: t("contacts.messages.success_with_response_time")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
