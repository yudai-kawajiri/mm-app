# frozen_string_literal: true

# ApplicationController
#
# 全コントローラーの基底クラス
# マルチテナント対応により、テナント（会社）とストア（店舗）のスコープを管理
class ApplicationController < ActionController::Base
  layout :layout_by_resource

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  before_action :redirect_if_authenticated, if: -> { devise_controller? && action_name == "new" && controller_name == "sessions" }

  helper_method :current_tenant, :current_store

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :invitation_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def after_sign_in_path_for(resource)
    authenticated_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def layout_by_resource
    return "print" if action_name == "print"

    if devise_controller? && !user_signed_in?
      "application"
    elsif user_signed_in?
      "authenticated_layout"
    else
      "application"
    end
  end

  def user_for_paper_trail
    user_signed_in? ? current_user.id : nil
  end

  # マルチテナント: 現在のユーザーが所属する会社
  def current_tenant
    current_user&.tenant
  end

  # マルチテナント: 現在のストア
  # - 一般ユーザー/店舗管理者: 自分が所属する店舗
  # - 会社管理者/スーパー管理者: セッションで選択中の店舗（未選択時は全店舗）
  def current_store
    @current_store ||= if session[:current_store_id].present? && current_user&.can_manage_company?
      current_tenant&.stores&.find_by(id: session[:current_store_id])
    else
      current_user&.store
    end
  end

  # マルチテナント: Products のデータスコープ
  # 会社管理者は店舗選択により表示範囲を切り替え可能
  def scoped_products
    return Resources::Product.none unless current_tenant

    if current_user.can_manage_company? && current_store
      Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store.id)
    elsif current_user.can_manage_company?
      Resources::Product.where(tenant_id: current_tenant.id)
    else
      Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Materials のデータスコープ
  def scoped_materials
    return Resources::Material.none unless current_tenant

    if current_user.can_manage_company? && current_store
      Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store.id)
    elsif current_user.can_manage_company?
      Resources::Material.where(tenant_id: current_tenant.id)
    else
      Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Plans のデータスコープ
  def scoped_plans
    return Resources::Plan.none unless current_tenant

    if current_user.can_manage_company? && current_store
      Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store.id)
    elsif current_user.can_manage_company?
      Resources::Plan.where(tenant_id: current_tenant.id)
    else
      Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  private

  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to authenticated_root_path
  end
end
