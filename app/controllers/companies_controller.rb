class CompaniesController < ApplicationController
  before_action :authenticate_user!

  def switch
    # 空文字列の場合もnilとして扱う
    company_id = params[:current_company_id].presence

    if company_id
      company = Company.find_by(id: company_id)
      if company
        session[:current_company_id] = company.id
        session[:current_store_id] = nil # 会社変更時は店舗選択をリセット
        flash[:notice] = t("flash_messages.companies.messages.switch_not_found", company_name: company.name)
        redirect_to company_dashboards_path(company_slug: company.slug)
        nil
      else
        flash[:alert] = t("flash_messages.admin.companies.messages.switch_not_found")
        redirect_to company_dashboards_path(company_slug: current_company&.slug || "admin")
        nil
      end
    else
      # 全会社モード（システム管理モード）
      session[:current_company_id] = nil
      session[:current_store_id] = nil
      flash[:notice] = t("flash_messages.companies.messages.switch_all_companies")
      redirect_to company_dashboards_path(company_slug: "admin")
      nil
    end
  end
end
