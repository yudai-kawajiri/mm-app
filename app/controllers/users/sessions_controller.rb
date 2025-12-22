# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  def new
    # ログイン画面表示前にチェック
    if user_signed_in? && current_user.super_admin? && !admin_path?
      sign_out current_user
      flash[:alert] = t('errors.messages.unauthorized')
      return redirect_to new_user_session_url, allow_other_host: true
    end

    super
  end

  # POST /resource/sign_in
  def create
    # ログイン前にチェック
    if params[:user] && params[:user][:email].present?
      user = User.find_by(email: params[:user][:email])
      if user&.super_admin? && !admin_path?
        flash.now[:alert] = t('errors.messages.unauthorized')
        self.resource = resource_class.new(sign_in_params)
        render :new, status: :unprocessable_entity
        return
      end
    end

    super
  end

  protected

  # システム管理者用のパスかチェック
  def admin_path?
    request.path.start_with?(AdminConfig::ADMIN_PATH_PREFIX)
  end
end
