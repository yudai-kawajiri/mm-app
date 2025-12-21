# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  skip_before_action :check_super_admin_subdomain, only: [:new, :create, :destroy]
  before_action :check_admin_subdomain_for_login, only: [:new, :create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |user|
      # ログイン成功後にサブドメインチェック
      if user.super_admin? && request.subdomain != 'admin'
        sign_out user
        flash[:alert] = t('errors.invalid_subdomain_access')
        redirect_to new_user_session_url(subdomain: 'admin'), allow_other_host: true and return
      end
    end
  end

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
    # システム管理者がadmin以外のサブドメインでログイン画面を開こうとした場合
    if params[:user] && params[:user][:email].present?
      user = User.find_by(email: params[:user][:email])
      if user&.super_admin? && request.subdomain != 'admin'
        flash.now[:alert] = t('errors.invalid_subdomain_access')
      end
    end
  end
end
