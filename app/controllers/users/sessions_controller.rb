# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  def new
    # ログイン画面表示前にチェック
    if user_signed_in? && current_user.super_admin? && request.subdomain != "admin"
      sign_out current_user
      flash[:alert] = t("errors.invalid_subdomain_access")
      return redirect_to new_user_session_url(subdomain: "admin"), allow_other_host: true
    end

    super
  end

  # POST /resource/sign_in
  def create
    # ログイン前にチェック
    if params[:user] && params[:user][:email].present?
      user = User.find_by(email: params[:user][:email])
      if user&.super_admin? && request.subdomain != "admin"
        flash.now[:alert] = t("errors.invalid_subdomain_access")
        self.resource = resource_class.new(sign_in_params)
        render :new, status: :unprocessable_entity
        return
      end
    end

    super
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
