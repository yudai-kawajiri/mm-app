# frozen_string_literal: true

class CompaniesController < AuthenticatedController
  before_action :authorize_super_admin!, only: [:switch]

  # テナント切替（システム管理者専用）
  def switch
    # 空文字列の場合もnilとして扱う
    company_id = params[:current_company_id].presence

    if company_id
      company = Company.find_by(id: company_id)
      if company
        session[:current_company_id] = company.id
        session[:current_store_id] = nil # テナント変更時は店舗選択をリセット
        flash[:notice] = t("companies.switch.success", company_name: company.name)
        redirect_to company_dashboards_path(company_slug: company.slug)
        return
      else
        flash[:alert] = t("companies.switch.not_found")
      end
    else
      # システム管理モード（全テナント）
      session[:current_company_id] = nil
      session[:current_store_id] = nil
      flash[:notice] = t("companies.switch.all_companies")
    end

    redirect_to request.referer || company_dashboards_path(company_slug: current_company.slug)
  end

  private

  def authorize_super_admin!
    unless current_user&.super_admin?
      redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t("errors.messages.unauthorized")
    end
  end
end
