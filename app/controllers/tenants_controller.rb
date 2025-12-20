# frozen_string_literal: true

class TenantsController < AuthenticatedController
  before_action :require_super_admin

  # テナント切替（システム管理者専用）
  def switch
    if params[:current_tenant_id].present?
      tenant = Tenant.find_by(id: params[:current_tenant_id])
      if tenant
        session[:current_tenant_id] = tenant.id
        session[:current_store_id] = nil # テナント変更時は店舗選択をリセット
        flash[:notice] = t('tenants.switch.success', tenant_name: tenant.name)
      else
        flash[:alert] = t('tenants.switch.not_found')
      end
    else
      # システム管理モード（全テナント）
      session[:current_tenant_id] = nil
      session[:current_store_id] = nil
      flash[:notice] = t('tenants.switch.all_tenants')
    end

    redirect_to request.referer || authenticated_root_path
  end

  private

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to authenticated_root_path, alert: t('errors.messages.unauthorized')
    end
  end
end
