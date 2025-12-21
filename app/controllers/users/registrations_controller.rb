# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # POST /resource
  def create
    build_resource(sign_up_params)

    # テナントを設定
    resource.company = current_company
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

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :invitation_code, :store_id ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone ])
  end

  def after_sign_up_path_for(resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  private

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
