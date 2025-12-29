class ApplicationRequestsController < ApplicationController
  before_action :find_application_request_by_token, only: [ :accept, :accept_confirm ]

  def new
    @application_request = ApplicationRequest.new
  end

  def create
    # 最初に @application_request を作成（rescue でも使えるようにする）
    @application_request = ApplicationRequest.new(application_request_params)

    ActiveRecord::Base.transaction do
      # 1. 会社を作成
      company = Company.create!(
        name: application_request_params[:company_name],
        code: SecureRandom.alphanumeric(8).upcase,
        email: application_request_params[:company_email],
        phone: application_request_params[:company_phone],
        slug: SecureRandom.alphanumeric(6).downcase
      )

      # 2. ApplicationRequest を作成
      @application_request.company = company
      @application_request.status = :pending
      @application_request.invitation_token = SecureRandom.urlsafe_base64(32)
      @application_request.save!

      # 3. 初期パスワードを生成
      temporary_password = SecureRandom.alphanumeric(12)

      # 4. ユーザーを作成（未承認状態）
      user = User.create!(
        email: @application_request.admin_email,
        password: temporary_password,
        password_confirmation: temporary_password,
        name: @application_request.admin_name,
        company: company,
        role: :company_admin,
        approved: false
      )

      @application_request.update!(user: user)

      # 5. 初期パスワードを ApplicationRequest に保存（メール送信用）
      @application_request.update_column(:temporary_password, temporary_password)

      # 6. 招待メールを送信
      ApplicationRequestMailer.invitation_email(@application_request, company.slug).deliver_later

      redirect_to thanks_application_requests_path
    end
  rescue ActiveRecord::RecordInvalid => e
    # エラーの詳細をログに出力
    Rails.logger.error("ApplicationRequest creation failed: #{e.record.errors.full_messages}")

    # エラーメッセージを @application_request に追加
    @application_request.errors.add(:base, e.record.errors.full_messages.join(", "))

    flash.now[:alert] = t("flash_messages.application_requests.create.error", error: e.record.errors.full_messages.join(", "))
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique => e
    # 重複キーエラーの処理
    Rails.logger.error("Duplicate key error: #{e.message}")

    # エラーメッセージを判定
    if e.message.include?("index_companies_on_phone")
      error_message = t('flash_messages.application_requests.create.duplicate_phone')
    elsif e.message.include?("index_companies_on_email")
      error_message = t('flash_messages.application_requests.create.duplicate_email')
    else
      error_message = t('flash_messages.application_requests.create.error')
    end

    @application_request.errors.add(:base, error_message)
    flash.now[:alert] = error_message
    render :new, status: :unprocessable_entity
  end

  def thanks
  end

  def accept
    # 招待トークンが有効かチェック
    if @application_request.status == "accepted"
      redirect_to company_new_user_session_path(company_slug: @application_request.company.slug),
        alert: t("application_requests.accept.already_used")
    end
  end

  def accept_confirm
    ActiveRecord::Base.transaction do
      # ユーザーを承認
      user = @application_request.user
      user.update!(approved: true)

      @application_request.update!(status: :accepted)

      redirect_to company_new_user_session_path(company_slug: @application_request.company.slug),
        notice: t("application_requests.accept_confirm.approved")
    end
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = t("application_requests.accept_confirm.approval_failed", error: e.record.errors.full_messages.join(', '))
    render :accept, status: :unprocessable_entity
  end

  private

  def application_request_params
    params.require(:application_request).permit(
      :company_name,
      :company_email,
      :company_phone,
      :admin_name,
      :admin_email,
    )
  end

  def find_application_request_by_token
    @application_request = ApplicationRequest.find_by!(invitation_token: params[:token])
  end
end
