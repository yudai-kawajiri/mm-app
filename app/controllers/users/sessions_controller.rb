# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |resource|
      # システム管理者のサブドメインチェック(ログイン成功後)
      if resource.super_admin? && request.subdomain != 'admin'
        sign_out resource
        flash[:alert] = t('errors.invalid_subdomain_access')
        redirect_to new_user_session_url(subdomain: 'admin'), allow_other_host: true and return
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
