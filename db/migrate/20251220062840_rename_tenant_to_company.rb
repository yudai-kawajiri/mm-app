class RenameTenantToCompany < ActiveRecord::Migration[7.1]
  def change
    # 1. テーブル名を変更
    rename_table :tenants, :companies

    # 2. 各テーブルの tenant_id を company_id にリネーム
    rename_column :users, :tenant_id, :company_id
    rename_column :stores, :tenant_id, :company_id
    rename_column :admin_requests, :tenant_id, :company_id
    rename_column :application_requests, :tenant_id, :company_id
    rename_column :products, :tenant_id, :company_id
    rename_column :materials, :tenant_id, :company_id
    rename_column :plans, :tenant_id, :company_id
    rename_column :categories, :tenant_id, :company_id
    rename_column :units, :tenant_id, :company_id
    rename_column :material_order_groups, :tenant_id, :company_id
    rename_column :daily_targets, :tenant_id, :company_id
    rename_column :monthly_budgets, :tenant_id, :company_id
    rename_column :plan_schedules, :tenant_id, :company_id
    rename_column :product_materials, :tenant_id, :company_id
    rename_column :plan_products, :tenant_id, :company_id
    rename_column :active_storage_attachments, :tenant_id, :company_id
    rename_column :versions, :tenant_id, :company_id

    # 3. インデックス名も自動的に変更される
  end
end
