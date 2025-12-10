class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.valid?
      # メール送信処理（後で実装）
      ContactMailer.contact_email(@contact).deliver_later

      redirect_to contact_thanks_path, notice: t('contacts.messages.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
    # お問い合わせ送信完了ページ
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
