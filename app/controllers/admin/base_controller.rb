# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  skip_before_action :auto_login_pending_user
  before_action :authenticate_user!
  before_action :require_admin

  private

  def require_admin
    unless current_user&.store_admin? || current_user&.company_admin? || current_user&.super_admin?
      redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t("errors.messages.unauthorized")
    end
  end
end
