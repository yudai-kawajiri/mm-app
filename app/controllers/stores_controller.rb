# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_company_admin

  def switch
    store_id = params[:store_id]
    
    if store_id.blank?
      session[:current_store_id] = nil
      flash[:notice] = t('stores.switch.all_stores')
    else
      store = current_user.tenant.stores.find_by(id: store_id)
      if store
        session[:current_store_id] = store.id
        flash[:notice] = t('stores.switch.success', store_name: store.name)
      else
        flash[:alert] = t('stores.switch.not_found')
      end
    end
    
    # 元のページに戻る（Refererがあればそこへ、なければダッシュボード）
    redirect_to request.referer || authenticated_root_path
  end
end
