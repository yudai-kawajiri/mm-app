# frozen_string_literal: true

class Management::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_store_or_company_admin

  private

  def require_store_or_company_admin
    unless current_user&.store_admin? || current_user&.general? || current_user&.can_manage_company?
      redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t("errors.messages.unauthorized")
    end
  end

  # 店舗ユーザー専用(システム管理者・会社管理者は不可)
  def require_store_user
    if current_user.super_admin? || current_user.company_admin?
      redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t("flash_messages.not_authorized")
    end
  end
end
