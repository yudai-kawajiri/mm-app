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
        flash[:notice] = t("companies.switch.success", company_name: company.name)
        redirect_to company_dashboards_path(company_slug: company.slug)
        return
      else
        flash[:alert] = t("companies.switch.not_found")
        redirect_to company_dashboards_path(company_slug: current_company&.slug || 'admin')
        return
      end
    else
      # 全会社モード（システム管理モード）
      session[:current_company_id] = nil
      session[:current_store_id] = nil
      flash[:notice] = t("companies.switch.all_companies")
      redirect_to company_dashboards_path(company_slug: 'admin')
      return
    end
  end
end
