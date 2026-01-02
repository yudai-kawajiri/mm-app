class AddCascadeToCompanyRelatedForeignKeys < ActiveRecord::Migration[8.1]
  def change
    # ==========================================
    # Company に関連するテーブル
    # ==========================================

    # Users → Companies (CASCADE: 会社削除時にユーザーも削除)
    remove_foreign_key :users, :companies if foreign_key_exists?(:users, :companies)
    add_foreign_key :users, :companies, on_delete: :cascade

    # Stores → Companies (CASCADE: 会社削除時に店舗も削除)
    remove_foreign_key :stores, :companies if foreign_key_exists?(:stores, :companies)
    add_foreign_key :stores, :companies, on_delete: :cascade

    # AdminRequests → Companies (CASCADE: 会社削除時に管理者リクエストも削除)
    remove_foreign_key :admin_requests, :companies if foreign_key_exists?(:admin_requests, :companies)
    add_foreign_key :admin_requests, :companies, on_delete: :cascade

    # ApplicationRequests → Companies (CASCADE: 会社削除時にアプリケーションリクエストも削除)
    if table_exists?(:application_requests) && foreign_key_exists?(:application_requests, :companies)
      remove_foreign_key :application_requests, :companies
      add_foreign_key :application_requests, :companies, on_delete: :cascade
    end

    # Categories → Companies (CASCADE: 会社削除時にカテゴリーも削除)
    remove_foreign_key :categories, :companies if foreign_key_exists?(:categories, :companies)
    add_foreign_key :categories, :companies, on_delete: :cascade

    # Materials → Companies (CASCADE: 会社削除時に材料も削除)
    remove_foreign_key :materials, :companies if foreign_key_exists?(:materials, :companies)
    add_foreign_key :materials, :companies, on_delete: :cascade

    # Products → Companies (CASCADE: 会社削除時に製品も削除)
    remove_foreign_key :products, :companies if foreign_key_exists?(:products, :companies)
    add_foreign_key :products, :companies, on_delete: :cascade

    # Plans → Companies (CASCADE: 会社削除時に計画も削除)
    if table_exists?(:plans) && foreign_key_exists?(:plans, :companies)
      remove_foreign_key :plans, :companies
      add_foreign_key :plans, :companies, on_delete: :cascade
    end

    # MonthlyBudgets → Companies (CASCADE: 会社削除時に月次予算も削除)
    if table_exists?(:monthly_budgets) && foreign_key_exists?(:monthly_budgets, :companies)
      remove_foreign_key :monthly_budgets, :companies
      add_foreign_key :monthly_budgets, :companies, on_delete: :cascade
    end

    # Units → Companies (CASCADE: 会社削除時に単位も削除)
    if table_exists?(:units) && foreign_key_exists?(:units, :companies)
      remove_foreign_key :units, :companies
      add_foreign_key :units, :companies, on_delete: :cascade
    end

    # MaterialOrderGroups → Companies (CASCADE: 会社削除時に発注グループも削除)
    if table_exists?(:material_order_groups) && foreign_key_exists?(:material_order_groups, :companies)
      remove_foreign_key :material_order_groups, :companies
      add_foreign_key :material_order_groups, :companies, on_delete: :cascade
    end

    # PlanSchedules → Companies (CASCADE: 会社削除時に計画スケジュールも削除)
    if table_exists?(:plan_schedules) && foreign_key_exists?(:plan_schedules, :companies)
      remove_foreign_key :plan_schedules, :companies
      add_foreign_key :plan_schedules, :companies, on_delete: :cascade
    end

    # Versions → Companies (CASCADE: 会社削除時にバージョン履歴も削除)
    if table_exists?(:versions) && foreign_key_exists?(:versions, :company_id)
      remove_foreign_key :versions, column: :company_id
      add_foreign_key :versions, :companies, column: :company_id, on_delete: :cascade
    end

    # PlanProducts → Companies (CASCADE: 会社削除時に計画製品も削除)
    if table_exists?(:plan_products) && foreign_key_exists?(:plan_products, :companies)
      remove_foreign_key :plan_products, :companies
      add_foreign_key :plan_products, :companies, on_delete: :cascade
    end

    # ==========================================
    # Store に関連するテーブル
    # ==========================================

    # Users → Stores (NULLIFY: 店舗削除時にユーザーの店舗参照をNULLに)
    remove_foreign_key :users, :stores if foreign_key_exists?(:users, :stores)
    add_foreign_key :users, :stores, on_delete: :nullify

    # Categories → Stores (CASCADE: 店舗削除時にカテゴリーも削除)
    remove_foreign_key :categories, :stores if foreign_key_exists?(:categories, :stores)
    add_foreign_key :categories, :stores, on_delete: :cascade

    # Materials → Stores (CASCADE: 店舗削除時に材料も削除)
    remove_foreign_key :materials, :stores if foreign_key_exists?(:materials, :stores)
    add_foreign_key :materials, :stores, on_delete: :cascade

    # Products → Stores (CASCADE: 店舗削除時に製品も削除)
    remove_foreign_key :products, :stores if foreign_key_exists?(:products, :stores)
    add_foreign_key :products, :stores, on_delete: :cascade

    # Plans → Stores (CASCADE: 店舗削除時に計画も削除)
    if table_exists?(:plans) && foreign_key_exists?(:plans, :stores)
      remove_foreign_key :plans, :stores
      add_foreign_key :plans, :stores, on_delete: :cascade
    end

    # MaterialOrderGroups → Stores (CASCADE: 店舗削除時に発注グループも削除)
    if table_exists?(:material_order_groups) && foreign_key_exists?(:material_order_groups, :stores)
      remove_foreign_key :material_order_groups, :stores
      add_foreign_key :material_order_groups, :stores, on_delete: :cascade
    end

    # DailyTargets → Stores (CASCADE: 店舗削除時に日次目標も削除)
    if table_exists?(:daily_targets) && foreign_key_exists?(:daily_targets, :stores)
      remove_foreign_key :daily_targets, :stores
      add_foreign_key :daily_targets, :stores, on_delete: :cascade
    end

    # MonthlyBudgets → Stores (CASCADE: 店舗削除時に月次予算も削除)
    if table_exists?(:monthly_budgets) && foreign_key_exists?(:monthly_budgets, :stores)
      remove_foreign_key :monthly_budgets, :stores
      add_foreign_key :monthly_budgets, :stores, on_delete: :cascade
    end

    # PlanSchedules → Stores (CASCADE: 店舗削除時に計画スケジュールも削除)
    if table_exists?(:plan_schedules) && foreign_key_exists?(:plan_schedules, :stores)
      remove_foreign_key :plan_schedules, :stores
      add_foreign_key :plan_schedules, :stores, on_delete: :cascade
    end

    # Units → Stores (CASCADE: 店舗削除時に単位も削除)
    if table_exists?(:units) && foreign_key_exists?(:units, :stores)
      remove_foreign_key :units, :stores
      add_foreign_key :units, :stores, on_delete: :cascade
    end

    # ==========================================
    # User に関連するテーブル
    # ==========================================

    # Categories → Users (CASCADE: ユーザー削除時にカテゴリーも削除)
    remove_foreign_key :categories, :users if foreign_key_exists?(:categories, :users)
    add_foreign_key :categories, :users, on_delete: :cascade

    # AdminRequests → Users (CASCADE: ユーザー削除時に管理者リクエストも削除)
    remove_foreign_key :admin_requests, :users if foreign_key_exists?(:admin_requests, :users)
    add_foreign_key :admin_requests, :users, on_delete: :cascade

    # AdminRequests → approved_by (NULLIFY: 承認者削除時にapproved_byをNULLに)
    if foreign_key_exists?(:admin_requests, column: :approved_by_id)
      remove_foreign_key :admin_requests, column: :approved_by_id
      add_foreign_key :admin_requests, :users, column: :approved_by_id, on_delete: :nullify
    end

    # ==========================================
    # Category に関連するテーブル
    # ==========================================

    # Materials → Categories (CASCADE: カテゴリー削除時に材料も削除)
    remove_foreign_key :materials, :categories if foreign_key_exists?(:materials, :categories)
    add_foreign_key :materials, :categories, on_delete: :cascade

    # Products → Categories (CASCADE: カテゴリー削除時に製品も削除)
    if foreign_key_exists?(:products, :categories)
      remove_foreign_key :products, :categories
      add_foreign_key :products, :categories, on_delete: :cascade
    end

    # Plans → Categories (CASCADE: カテゴリー削除時に計画も削除)
    if table_exists?(:plans) && foreign_key_exists?(:plans, :categories)
      remove_foreign_key :plans, :categories
      add_foreign_key :plans, :categories, on_delete: :cascade
    end

    # ==========================================
    # Material に関連するテーブル
    # ==========================================

    # ProductMaterials → Materials (CASCADE: 材料削除時に製品材料も削除)
    if table_exists?(:product_materials) && foreign_key_exists?(:product_materials, :materials)
      remove_foreign_key :product_materials, :materials
      add_foreign_key :product_materials, :materials, on_delete: :cascade
    end

    # ==========================================
    # Product に関連するテーブル
    # ==========================================

    # ProductMaterials → Products (CASCADE: 製品削除時に製品材料も削除)
    if table_exists?(:product_materials) && foreign_key_exists?(:product_materials, :products)
      remove_foreign_key :product_materials, :products
      add_foreign_key :product_materials, :products, on_delete: :cascade
    end

    # PlanProducts → Products (CASCADE: 製品削除時に計画製品も削除)
    if table_exists?(:plan_products) && foreign_key_exists?(:plan_products, :products)
      remove_foreign_key :plan_products, :products
      add_foreign_key :plan_products, :products, on_delete: :cascade
    end

    # ==========================================
    # MonthlyBudget に関連するテーブル
    # ==========================================

    # DailyTargets → MonthlyBudgets (CASCADE: 月次予算削除時に日次目標も削除)
    if table_exists?(:daily_targets) && foreign_key_exists?(:daily_targets, :monthly_budgets)
      remove_foreign_key :daily_targets, :monthly_budgets
      add_foreign_key :daily_targets, :monthly_budgets, on_delete: :cascade
    end

    # ==========================================
    # Plan に関連するテーブル
    # ==========================================

    # PlanProducts → Plans (CASCADE: 計画削除時に計画製品も削除)
    if table_exists?(:plan_products) && table_exists?(:plans) && foreign_key_exists?(:plan_products, :plans)
      remove_foreign_key :plan_products, :plans
      add_foreign_key :plan_products, :plans, on_delete: :cascade
    end

    # PlanSchedules → Plans (CASCADE: 計画削除時に計画スケジュールも削除)
    if table_exists?(:plan_schedules) && table_exists?(:plans) && foreign_key_exists?(:plan_schedules, :plans)
      remove_foreign_key :plan_schedules, :plans
      add_foreign_key :plan_schedules, :plans, on_delete: :cascade
    end

    # ==========================================
    # MaterialOrderGroup に関連するテーブル
    # ==========================================

    # Materials → MaterialOrderGroups (NULLIFY: 発注グループ削除時に材料のorder_group_idをNULLに)
    if foreign_key_exists?(:materials, column: :order_group_id)
      remove_foreign_key :materials, column: :order_group_id
      add_foreign_key :materials, :material_order_groups, column: :order_group_id, on_delete: :nullify
    end
  end
end
