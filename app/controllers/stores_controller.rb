# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_super_admin_or_company_admin

  # 店舗切替
  #
  # システム管理者または会社管理者が店舗を切り替える
  def switch
    if params[:current_store_id].present?
      store = current_company&.stores&.find_by(id: params[:current_store_id])
      if store
        session[:current_store_id] = store.id
        flash[:notice] = t("stores.switch.success", store_name: store.name)
      else
        flash[:alert] = t("stores.switch.not_found")
      end
    else
      # 全店舗を選択
      session[:current_store_id] = nil
      flash[:notice] = t("stores.switch.all_stores")
    end

    redirect_to request.referer || company_dashboards_path(company_slug: current_company.slug)
  end

  private

  def require_super_admin_or_company_admin
    unless current_user.super_admin? || current_user.company_admin?
      flash[:alert] = t("errors.unauthorized")
      redirect_to company_dashboards_path(company_slug: current_company.slug)
    end
  end
end
