# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  before_action :check_admin_subdomain_for_login, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def check_admin_subdomain_for_login
    # ログイン試行前にチェック
    return unless params[:user] && params[:user][:email].present?
    
    user = User.find_by(email: params[:user][:email])
    if user&.super_admin? && request.subdomain != 'admin'
      # ログインを中断
      flash[:alert] = t('errors.invalid_subdomain_access')
      redirect_to new_user_session_url(subdomain: 'admin'), allow_other_host: true
    end
  end
end
