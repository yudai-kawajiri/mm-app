class AddCompanyAndStoreToAllTables < ActiveRecord::Migration[8.0]
  def change
    # Users
    add_reference :users, :company, foreign_key: true, null: true
    add_reference :users, :store, foreign_key: true, null: true

    # Products
    add_reference :products, :company, foreign_key: true, null: true
    add_reference :products, :store, foreign_key: true, null: true

    # Materials
    add_reference :materials, :company, foreign_key: true, null: true
    add_reference :materials, :store, foreign_key: true, null: true

    # Plans
    add_reference :plans, :company, foreign_key: true, null: true
    add_reference :plans, :store, foreign_key: true, null: true

    # MaterialOrderGroups
    add_reference :material_order_groups, :company, foreign_key: true, null: true
    add_reference :material_order_groups, :store, foreign_key: true, null: true

    # Categories
    add_reference :categories, :company, foreign_key: true, null: true
    add_reference :categories, :store, foreign_key: true, null: true

    # DailyTargets
    add_reference :daily_targets, :company, foreign_key: true, null: true
    add_reference :daily_targets, :store, foreign_key: true, null: true

    # MonthlyBudgets
    add_reference :monthly_budgets, :company, foreign_key: true, null: true
    add_reference :monthly_budgets, :store, foreign_key: true, null: true

    # PlanSchedules
    add_reference :plan_schedules, :company, foreign_key: true, null: true
    add_reference :plan_schedules, :store, foreign_key: true, null: true

    # Units
    add_reference :units, :company, foreign_key: true, null: true
    add_reference :units, :store, foreign_key: true, null: true

    # ProductMaterials
    add_reference :product_materials, :company, foreign_key: true, null: true

    # PlanProducts
    add_reference :plan_products, :company, foreign_key: true, null: true

    # ActiveStorageAttachments
    add_reference :active_storage_attachments, :company, foreign_key: true, null: true
    add_reference :active_storage_attachments, :store, foreign_key: true, null: true

    # Versions
    add_reference :versions, :company, foreign_key: true, null: true
  end
end
