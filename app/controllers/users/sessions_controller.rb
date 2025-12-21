# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # ログイン後のリダイレクト先をパスベースに変更
  def after_sign_in_path_for(resource)
    if resource.company.present?
      # パスベース: /c/:company_subdomain/dashboards へリダイレクト
      company_dashboards_path(company_subdomain: resource.company.subdomain)
    else
      # 会社がない場合は選択画面へ
      select_company_path
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
