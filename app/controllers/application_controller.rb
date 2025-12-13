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
  # - 会社管理者: セッションで選択した店舗（切り替え可能、未選択時は全店舗=nil）
  #
  # 【なぜ .to_s.strip か】
  # フォームから送信される「全店舗」選択時、session[:current_store_id] が空文字列 "" になる
  # .present? だけでは "" を true と判定してしまうため、明示的に正規化が必要
  def current_store
    @current_store ||= if current_user&.can_manage_company?
      store_id = session[:current_store_id].to_s.strip
      store_id.present? ? current_tenant&.stores&.find_by(id: store_id) : nil
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
  def scoped_products
    return Resources::Product.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::Product.where(tenant_id: current_tenant.id)
      end
    else
      Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Materials のデータスコープ
  def scoped_materials
    return Resources::Material.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::Material.where(tenant_id: current_tenant.id)
      end
    else
      Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Plans のデータスコープ
  def scoped_plans
    return Resources::Plan.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::Plan.where(tenant_id: current_tenant.id)
      end
    else
      Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Categories のデータスコープ
  def scoped_categories
    return Resources::Category.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::Category.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::Category.where(tenant_id: current_tenant.id)
      end
    else
      Resources::Category.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: Units のデータスコープ
  def scoped_units
    return Resources::Unit.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::Unit.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::Unit.where(tenant_id: current_tenant.id)
      end
    else
      Resources::Unit.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: MaterialOrderGroups のデータスコープ
  def scoped_material_order_groups
    return Resources::MaterialOrderGroup.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id)
      end
    else
      Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: MonthlyBudgets のデータスコープ
  #
  # 【業務要件】
  # 月次予算は店舗ごとに異なる目標を設定するため、店舗スコープが必須
  # 会社管理者は複数店舗の予算を横断して確認・比較する必要がある
  def scoped_monthly_budgets
    return Management::MonthlyBudget.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Management::MonthlyBudget.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Management::MonthlyBudget.where(tenant_id: current_tenant.id)
      end
    else
      Management::MonthlyBudget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: DailyTargets のデータスコープ
  #
  # 【業務要件】
  # 日次目標は月次予算に紐づくため、同じスコープロジックを適用
  # 店舗スタッフは自店舗の日次目標のみ閲覧・達成状況を確認
  def scoped_daily_targets
    return Management::DailyTarget.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Management::DailyTarget.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Management::DailyTarget.where(tenant_id: current_tenant.id)
      end
    else
      Management::DailyTarget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: PlanSchedules のデータスコープ
  #
  # 【業務要件】
  # 計画スケジュールは店舗ごとの生産計画を管理
  # 店舗間でのスケジュール共有は不要（各店舗が独立して計画を立てる）
  def scoped_plan_schedules
    return Planning::PlanSchedule.none unless current_tenant

    if current_user.can_manage_company?
      if current_store
        Planning::PlanSchedule.where(tenant_id: current_tenant.id, store_id: current_store.id)
      else
        Planning::PlanSchedule.where(tenant_id: current_tenant.id)
      end
    else
      Planning::PlanSchedule.where(tenant_id: current_tenant.id, store_id: current_store&.id)
    end
  end

  # マルチテナント: 新規登録・編集可能かどうか判定
  #
  # 【業務要件】
  # 会社管理者が「全店舗」選択中は新規登録・編集を禁止
  # データは必ず特定の店舗に紐づける必要がある
  #
  # 【なぜこの制約か】
  # store_id = nil のデータは「どの店舗にも属さない」状態となり、
  # データの所有権が曖昧になるため、業務上認められない
  #
  # 【View での使用】
  # helper_method として公開され、View 側で新規登録ボタンの表示/非表示を制御
  def can_register?
    return true unless current_user&.can_manage_company?
    current_store.present?
  end
  helper_method :can_register?

  # 新規登録・編集前チェック: 店舗が選択されていない場合はリダイレクト
  #
  # 【適用対象アクション】
  # - new, edit: フォーム画面へのアクセス制限
  # - create, update: データ登録・更新の実行制限
  # - copy: データコピーの実行制限
  #
  # 【リダイレクト先】
  # 各コントローラの index ページ（一覧画面）に統一
  def require_store_selected
    return if can_register?

    flash[:alert] = t("flash_messages.require_store_selected")

    controller_name = self.class.name.underscore.gsub('_controller', '')
    index_path = url_for(controller: controller_name, action: :index, only_path: true)
    redirect_to index_path
  end

  private

  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to authenticated_root_path
  end
end
