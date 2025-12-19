# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  private

  def require_admin
    unless current_user&.store_admin? || current_user&.company_admin? || current_user&.super_admin?
      redirect_to authenticated_root_path, alert: t("errors.messages.unauthorized")
    end
  end
end
