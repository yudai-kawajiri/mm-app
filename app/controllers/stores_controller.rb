# frozen_string_literal: true

class StoresController < AuthenticatedController
  before_action :require_company_admin

  # 店舗切替
  #
  # 【リダイレクト先の判定】
  # - フォーム画面（/new, /edit）から: 一覧ページへリダイレクト（無限ループ防止）
  # - その他の画面から: 元のページに留まる
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

    referer = request.referer || authenticated_root_path
    if referer.match?(/\/(new|\d+\/edit)(\?.*)?$/)
      redirect_to referer.gsub(/\/(new|\d+\/edit)(\?.*)?$/, '')
    else
      redirect_to referer
    end
  end
end
