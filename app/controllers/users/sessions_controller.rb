# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :check_super_admin_subdomain, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:destroy]
  
  # GET /users/sign_in
  def new
    # 既にログインしている場合は一旦ログアウト
    if user_signed_in?
      sign_out(current_user)
      flash[:notice] = '前回のセッションからログアウトしました。再度ログインしてください。'
    end
    super
  end
  
  # POST /users/sign_in
  def create
    # システム管理者の場合、サブドメインチェックをスキップ
    email = params.dig(:user, :email)
    user = User.find_by(email: email) if email.present?
    
    if user&.super_admin?
      # システム管理者用のログイン処理
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      # 通常のログイン処理（サブドメインチェックあり）
      super
    end
  end
  
  # DELETE /users/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    
    # ログアウト成功パラメータを付けて localhost へ強制リダイレクト
    redirect_to "http://localhost:#{request.port}/?logout=success", allow_other_host: true and return
  end
end
