# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :choose_layout
  before_action :set_company_from_slug
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  helper_method :current_company

  # POST /resource
  def create
    build_resource(sign_up_params)

    # テナントを設定
    resource.company = @company
    resource.approved = false

    resource.save
    yield resource if block_given?

    if resource.persisted?
      # 承認リクエストを作成
      create_admin_request(resource)

      # 未承認なので自動ログインはしない
      set_flash_message! :notice, :signed_up_but_not_approved
      expire_data_after_sign_in!
      respond_with resource, location: after_inactive_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def choose_layout
    action_name.in?(%w[new create]) ? "application" : "authenticated_layout"
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :invitation_code, :store_id ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone ])
  end

  def after_sign_up_path_for(resource)
    company_new_user_session_path(company_slug: params[:company_slug])
  end

  def after_inactive_sign_up_path_for(resource)
    company_new_user_session_path(company_slug: params[:company_slug])
  end

  private

  def set_company_from_slug
    @company = Company.find_by!(slug: params[:company_slug])
  end

  def current_company
    @company
  end

  def create_admin_request(user)
    AdminRequest.create!(
      company: user.company,
      store: user.store,
      user: user,
      request_type: "user_registration",
      status: "pending",
      message: "#{user.name} (#{user.email}) が新規登録を申請しました"
    )
  end
end
