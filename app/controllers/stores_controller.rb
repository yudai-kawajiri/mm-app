# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_company_admin

  # 店舗切替
  #
  # 会社管理者が店舗を切り替える
  def switch
    store = current_user.tenant.stores.find_by(id: params[:store_id])

    if store
      session[:current_store_id] = store.id
      flash[:notice] = t('stores.switch.success', store_name: store.name)
    else
      flash[:alert] = t('stores.switch.not_found')
    end

    redirect_to request.referer || authenticated_root_path
  end
end
