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
    # 会社管理者の初回ログイン時、店舗が未選択なら最初の店舗を自動選択
    if resource.can_manage_company? && session[:current_store_id].blank?
      first_store = resource.tenant&.stores&.first
      session[:current_store_id] = first_store&.id if first_store
    end

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
  #
  # 【設計意図】
  # User has_one Tenant の関係を基盤とし、全データアクセスの起点とする
  # これによりN+1を防ぎつつ、テナント分離を保証
  def current_tenant
    current_user&.tenant
  end

  # マルチテナント: 現在のストア
  #
  # 【権限による動作の違い】
  # - 一般ユーザー/店舗管理者: 所属店舗固定（変更不可）
  # - 会社管理者: セッションで選択した店舗（切り替え可能）
  def current_store
    @current_store ||= if current_user&.can_manage_company?
      current_tenant&.stores&.find_by(id: session[:current_store_id])
    else
      current_user&.store
    end
  end

  # マルチテナント: Products のデータスコープ
  #
  # 【スコープ設計】
  # 1. 会社管理者 + 店舗選択時: 選択店舗のデータのみ
  # 2. 会社管理者 + 全店舗選択: テナント全体のデータ
  # 3. 一般ユーザー: 所属店舗のデータのみ
  #
  # 【なぜこの実装か】
  # - N+1防止: eager loadingの起点となるベースクエリを提供
  # - セキュリティ: WHERE句でテナント・店舗を強制し、データ漏洩を防止
  # - パフォーマンス: インデックス活用（tenant_id + store_id）

  # マルチテナント: Materials のデータスコープ

  # マルチテナント: Plans のデータスコープ

  # マルチテナント: Categories のデータスコープ

  # マルチテナント: Units のデータスコープ

  # マルチテナント: MaterialOrderGroups のデータスコープ

  # マルチテナント: MonthlyBudgets のデータスコープ
  #
  # 【業務要件】
  # 月次予算は店舗ごとに異なる目標を設定するため、店舗スコープが必須
  # 会社管理者は複数店舗の予算を横断して確認・比較する必要がある
  def scoped_monthly_budgets
    return Management::MonthlyBudget.none unless current_tenant
    Management::MonthlyBudget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # カテゴリーのスコープ
  def scoped_categories
    Resources::Category.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # 商品のスコープ
  def scoped_products
    Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # 原材料のスコープ
  def scoped_materials
    Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # プランのスコープ
  def scoped_plans
    Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # 発注グループのスコープ
  def scoped_material_order_groups
    Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # 単位のスコープ
  def scoped_units
    Resources::Unit.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end










  # マルチテナント: DailyTargets のデータスコープ
  #
  # 【業務要件】
  # 日次目標は月次予算に紐づくため、同じスコープロジックを適用
  # 店舗スタッフは自店舗の日次目標のみ閲覧・達成状況を確認
  def scoped_daily_targets
    return Management::DailyTarget.none unless current_tenant
    Management::DailyTarget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  # マルチテナント: PlanSchedules のデータスコープ
  #
  # 【業務要件】
  # 計画スケジュールは店舗ごとの生産計画を管理
  # 店舗間でのスケジュール共有は不要（各店舗が独立して計画を立てる）
  def scoped_plan_schedules
    return Planning::PlanSchedule.none unless current_tenant
    Planning::PlanSchedule.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end



  private

  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to authenticated_root_path
  end
end
