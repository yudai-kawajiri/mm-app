# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  before_action :set_company_from_slug

  private

  def set_company_from_slug
    @company = Company.find_by!(slug: params[:company_slug]) if params[:company_slug]
  end

  def current_company
    @company
  end
  helper_method :current_company
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end


protected

def after_sending_reset_password_instructions_path_for(resource_name)
  company_new_user_session_path(company_slug: params[:company_slug])
end

def after_resetting_password_path_for(resource)
  company_new_user_session_path(company_slug: params[:company_slug])
end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
