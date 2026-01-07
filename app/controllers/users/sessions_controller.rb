# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :set_company_from_slug, only: [ :new, :create ]
  skip_before_action :verify_signed_out_user, only: :destroy, raise: false

  # GET /resource/sign_in
  def new
    # ログイン画面表示前にチェック
    if user_signed_in? && current_user.super_admin? && !admin_path?
      sign_out current_user
      flash[:alert] = t("errors.messages.unauthorized")
      return redirect_to new_user_session_url, allow_other_host: true
    end

    super
  end

  # POST /resource/sign_in
  def create
    # ログイン前にチェック
    if params[:user] && params[:user][:email].present?
      user = User.find_by(email: params[:user][:email])

      # スーパー管理者チェック
      if user&.super_admin? && !admin_path?
        flash.now[:alert] = t("errors.messages.unauthorized")
        self.resource = resource_class.new(sign_in_params)
        render :new, status: :unprocessable_entity
        return
      end

      # 会社チェック：システム管理者以外のユーザーが存在し、会社が一致しない場合は汎用エラー
      if user && @company && user.company_id != @company.id && !user.super_admin?
        flash.now[:alert] = t("errors.messages.invalid_credentials")
        self.resource = resource_class.new(sign_in_params)
        render :new, status: :unprocessable_entity
        return
      end
    end

    super
  end

  protected

  # ログイン後のリダイレクト先
  def after_sign_in_path_for(resource)
    if params[:company_slug].present?
      company_dashboards_path(company_slug: params[:company_slug])
    else
      root_path
    end
  end

  # システム管理者用のパスかチェック
  def admin_path?
    # システム管理者の会社スラッグでログインしている場合、または admin パス
    params[:company_slug] == "system-admin" ||
    request.path.start_with?("/c/system-admin", "/admin")
  end

  private

  def set_company_from_slug
    @company = Company.find_by(slug: params[:company_slug]) if params[:company_slug].present?
  end

  def current_company
    @company
  end
  helper_method :current_company
end
