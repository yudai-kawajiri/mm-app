# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_super_admin_or_company_admin

  # 店舗切替
  #
  # システム管理者または会社管理者が店舗を切り替える
  def switch
    if params[:store_id].present?
      store = current_tenant&.stores&.find_by(id: params[:store_id])
      if store
        session[:current_store_id] = store.id
        Rails.logger.debug "DEBUG: StoresController#switch - session[:current_store_id] = #{session[:current_store_id]}"
        flash[:notice] = t('stores.switch.success', store_name: store.name)
      else
        flash[:alert] = t('stores.switch.not_found')
      end
    else
      # 全店舗を選択
      session[:current_store_id] = nil
      Rails.logger.debug "DEBUG: StoresController#switch - session[:current_store_id] = nil (all stores)"
      flash[:notice] = t('stores.switch.all_stores')
    end

    redirect_to request.referer || authenticated_root_path
  end

  private

  def require_super_admin_or_company_admin
    unless current_user.super_admin? || current_user.company_admin?
      flash[:alert] = t('errors.unauthorized')
      redirect_to authenticated_root_path
    end
  end
end
