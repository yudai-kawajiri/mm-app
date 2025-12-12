# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_company_admin

  def switch
    store_id = params[:store_id]

    if store_id.blank?
      session[:current_store_id] = nil
      redirect_to authenticated_root_path, notice: t('stores.switch.all_stores')
    else
      store = current_user.tenant.stores.find_by(id: store_id)
      if store
        session[:current_store_id] = store.id
        redirect_to authenticated_root_path, notice: t('stores.switch.success', store_name: store.name)
      else
        redirect_to authenticated_root_path, alert: t('stores.switch.not_found')
      end
    end
  end
end
