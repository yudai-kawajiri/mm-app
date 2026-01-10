class CreateAllTablesWithUuid < ActiveRecord::Migration[8.1]
  def change
    # Companies テーブル（依存関係の最上位）
    create_table :companies, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email
      t.string :phone
      t.string :invitation_token
      t.timestamps
    end
    add_index :companies, :slug, unique: true
    add_index :companies, :invitation_token, unique: true
    add_index :companies, :phone, unique: true

    # Stores テーブル
    create_table :stores, id: :uuid do |t|
      t.string :name, null: false
      t.string :code
      t.string :invitation_code
      t.boolean :active, default: true, null: false
      t.uuid :company_id, null: false
      t.timestamps
    end
    add_index :stores, :company_id
    add_index :stores, [ :company_id, :code ], unique: true
    add_foreign_key :stores, :companies, on_delete: :cascade

    # Users テーブル
    create_table :users, id: :uuid do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :name
      t.string :phone
      t.integer :role, default: 0, null: false
      t.boolean :approved, default: false, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :company_id
    add_index :users, :store_id
    add_index :users, :role
    add_index :users, :approved
    add_foreign_key :users, :companies, on_delete: :cascade
    add_foreign_key :users, :stores, on_delete: :nullify

    # Categories テーブル
    create_table :categories, id: :uuid do |t|
      t.string :name, null: false
      t.string :reading
      t.text :description
      t.integer :category_type
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :categories, :company_id
    add_index :categories, :store_id
    add_index :categories, :user_id
    add_index :categories, [ :name, :category_type, :store_id ], unique: true, name: 'index_categories_on_name_type_store'
    add_index :categories, [ :reading, :category_type, :store_id ], unique: true, name: 'index_categories_on_reading_type_store'
    add_foreign_key :categories, :companies, on_delete: :cascade
    add_foreign_key :categories, :stores, on_delete: :cascade
    add_foreign_key :categories, :users, on_delete: :cascade

    # Units テーブル
    create_table :units, id: :uuid do |t|
      t.string :name, null: false
      t.string :reading
      t.text :description
      t.integer :category
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :units, :company_id
    add_index :units, :store_id
    add_index :units, :user_id
    add_index :units, [ :name, :category, :store_id ], unique: true, name: 'index_units_on_name_category_store'
    add_index :units, [ :reading, :category, :store_id ], unique: true, name: 'index_units_on_reading_category_store'
    add_foreign_key :units, :companies, on_delete: :cascade
    add_foreign_key :units, :stores, on_delete: :cascade
    add_foreign_key :units, :users

    # Material Order Groups テーブル
    create_table :material_order_groups, id: :uuid do |t|
      t.string :name, null: false
      t.string :reading
      t.integer :materials_count, default: 0, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :material_order_groups, :company_id
    add_index :material_order_groups, :store_id
    add_index :material_order_groups, :user_id
    add_index :material_order_groups, [ :name, :store_id ], unique: true, name: 'index_material_order_groups_on_name_store'
    add_index :material_order_groups, [ :reading, :store_id ], unique: true, name: 'index_material_order_groups_on_reading_store'
    add_foreign_key :material_order_groups, :companies, on_delete: :cascade
    add_foreign_key :material_order_groups, :stores, on_delete: :cascade
    add_foreign_key :material_order_groups, :users

    # Materials テーブル
    create_table :materials, id: :uuid do |t|
      t.string :name, null: false
      t.string :reading
      t.text :description
      t.string :measurement_type, default: "weight", null: false
      t.decimal :default_unit_weight, precision: 10, scale: 3, comment: "デフォルトの1単位あたり重量（g）"
      t.decimal :unit_weight_for_order, precision: 10, scale: 3
      t.integer :pieces_per_order_unit, comment: "1発注単位あたりの個数（トレイなど）"
      t.integer :display_order
      t.string :order_group_name
      t.uuid :category_id, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.uuid :unit_for_order_id, null: false
      t.uuid :unit_for_product_id, null: false
      t.uuid :production_unit_id
      t.uuid :order_group_id
      t.timestamps
    end
    add_index :materials, :category_id
    add_index :materials, :company_id
    add_index :materials, :store_id
    add_index :materials, :user_id
    add_index :materials, :unit_for_order_id
    add_index :materials, :unit_for_product_id
    add_index :materials, :production_unit_id
    add_index :materials, :order_group_id
    add_index :materials, :measurement_type
    add_index :materials, [ :name, :category_id, :store_id ], unique: true, name: 'index_materials_on_name_category_store'
    add_index :materials, [ :reading, :category_id, :store_id ], unique: true, name: 'index_materials_on_reading_category_store'
    add_foreign_key :materials, :categories, on_delete: :cascade
    add_foreign_key :materials, :companies, on_delete: :cascade
    add_foreign_key :materials, :stores, on_delete: :cascade
    add_foreign_key :materials, :users
    add_foreign_key :materials, :units, column: :unit_for_order_id
    add_foreign_key :materials, :units, column: :unit_for_product_id
    add_foreign_key :materials, :units, column: :production_unit_id
    add_foreign_key :materials, :material_order_groups, column: :order_group_id, on_delete: :nullify

    # Products テーブル
    create_table :products, id: :uuid do |t|
      t.string :name, null: false
      t.string :item_number, null: false
      t.string :reading
      t.text :description
      t.integer :price, null: false
      t.integer :status
      t.integer :display_order
      t.uuid :category_id, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :products, :category_id
    add_index :products, :company_id
    add_index :products, :store_id
    add_index :products, :user_id
    add_index :products, [ :name, :category_id, :store_id ], unique: true, name: 'index_products_on_name_category_store'
    add_index :products, [ :item_number, :category_id, :store_id ], unique: true, name: 'index_products_on_item_number_category_store'
    add_index :products, [ :reading, :category_id, :store_id ], unique: true, name: 'index_products_on_reading_category_store'
    add_foreign_key :products, :categories, on_delete: :cascade
    add_foreign_key :products, :companies, on_delete: :cascade
    add_foreign_key :products, :stores, on_delete: :cascade
    add_foreign_key :products, :users

    # Product Materials テーブル（中間テーブル）
    create_table :product_materials, id: :uuid do |t|
      t.uuid :product_id, null: false
      t.uuid :material_id, null: false
      t.uuid :unit_id, null: false
      t.decimal :quantity, precision: 10, scale: 3, null: false
      t.decimal :unit_weight, precision: 10, scale: 3, null: false
      t.uuid :company_id
      t.timestamps
    end
    add_index :product_materials, :product_id
    add_index :product_materials, :material_id
    add_index :product_materials, :unit_id
    add_index :product_materials, :company_id
    add_index :product_materials, [ :product_id, :material_id ], unique: true
    add_foreign_key :product_materials, :products, on_delete: :cascade
    add_foreign_key :product_materials, :materials, on_delete: :cascade
    add_foreign_key :product_materials, :units
    add_foreign_key :product_materials, :companies

    # Plans テーブル
    create_table :plans, id: :uuid do |t|
      t.string :name, null: false
      t.string :reading
      t.text :description
      t.integer :status
      t.uuid :category_id, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :plans, :category_id
    add_index :plans, :company_id
    add_index :plans, :store_id
    add_index :plans, :user_id
    add_index :plans, [ :name, :category_id, :store_id ], unique: true, name: 'index_plans_on_name_category_store'
    add_index :plans, [ :reading, :category_id, :store_id ], unique: true, name: 'index_plans_on_reading_category_store'
    add_foreign_key :plans, :categories, on_delete: :cascade
    add_foreign_key :plans, :companies, on_delete: :cascade
    add_foreign_key :plans, :stores, on_delete: :cascade
    add_foreign_key :plans, :users

    # Plan Products テーブル（中間テーブル）
    create_table :plan_products, id: :uuid do |t|
      t.uuid :plan_id, null: false
      t.uuid :product_id, null: false
      t.integer :production_count, null: false
      t.uuid :company_id
      t.timestamps
    end
    add_index :plan_products, :plan_id
    add_index :plan_products, :product_id
    add_index :plan_products, :company_id
    add_index :plan_products, [ :plan_id, :product_id ], unique: true
    add_foreign_key :plan_products, :plans, on_delete: :cascade
    add_foreign_key :plan_products, :products, on_delete: :cascade
    add_foreign_key :plan_products, :companies, on_delete: :cascade

    # Monthly Budgets テーブル
    create_table :monthly_budgets, id: :uuid do |t|
      t.date :budget_month, null: false, comment: "予算対象月（月初日を保存）"
      t.bigint :target_amount, null: false, comment: "目標金額"
      t.decimal :target_discount_rate, precision: 5, scale: 2, default: 0.0, null: false, comment: "目標見切り率（%）"
      t.decimal :forecast_discount_rate, precision: 5, scale: 2, default: 0.0, null: false, comment: "予測見切り率（%）"
      t.text :description, comment: "説明"
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :monthly_budgets, :company_id
    add_index :monthly_budgets, :store_id
    add_index :monthly_budgets, :user_id
    add_index :monthly_budgets, [ :budget_month, :store_id ], unique: true
    add_foreign_key :monthly_budgets, :companies, on_delete: :cascade
    add_foreign_key :monthly_budgets, :stores, on_delete: :cascade
    add_foreign_key :monthly_budgets, :users

    # Daily Targets テーブル
    create_table :daily_targets, id: :uuid do |t|
      t.date :target_date, null: false
      t.bigint :target_amount, null: false, comment: "目標金額"
      t.text :description
      t.uuid :monthly_budget_id, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :daily_targets, :monthly_budget_id
    add_index :daily_targets, :company_id
    add_index :daily_targets, :store_id
    add_index :daily_targets, :user_id
    add_index :daily_targets, :target_date
    add_index :daily_targets, [ :monthly_budget_id, :target_date ], unique: true, name: 'index_daily_targets_on_budget_and_date'
    add_foreign_key :daily_targets, :monthly_budgets, on_delete: :cascade
    add_foreign_key :daily_targets, :companies
    add_foreign_key :daily_targets, :stores, on_delete: :cascade
    add_foreign_key :daily_targets, :users

    # Plan Schedules テーブル
    create_table :plan_schedules, id: :uuid do |t|
      t.date :scheduled_date, null: false, comment: "スケジュール実施日"
      t.integer :status, default: 0, null: false, comment: "ステータス"
      t.bigint :actual_revenue, comment: "実績売上"
      t.text :description, comment: "説明"
      t.jsonb :plan_products_snapshot, default: {}, null: false, comment: "計画商品のスナップショット（日別調整用）"
      t.uuid :plan_id
      t.uuid :company_id
      t.uuid :store_id
      t.uuid :user_id
      t.timestamps
    end
    add_index :plan_schedules, :plan_id
    add_index :plan_schedules, :company_id
    add_index :plan_schedules, :store_id
    add_index :plan_schedules, :user_id
    add_index :plan_schedules, :scheduled_date
    add_index :plan_schedules, [ :store_id, :scheduled_date ], unique: true
    add_index :plan_schedules, :plan_products_snapshot, using: :gin
    add_foreign_key :plan_schedules, :plans, on_delete: :cascade
    add_foreign_key :plan_schedules, :companies, on_delete: :cascade
    add_foreign_key :plan_schedules, :stores, on_delete: :cascade
    add_foreign_key :plan_schedules, :users

    # Application Requests テーブル
    create_table :application_requests, id: :uuid do |t|
      t.string :company_name
      t.string :company_email
      t.string :company_phone
      t.string :admin_name
      t.string :admin_email
      t.integer :status
      t.string :invitation_token
      t.datetime :invitation_sent_at
      t.string :temporary_password
      t.integer :company_id
      t.uuid :user_id
      t.timestamps
    end

    # Admin Requests テーブル
    create_table :admin_requests, id: :uuid do |t|
      t.integer :request_type, default: 0, null: false, comment: "0: store_admin_request"
      t.integer :status, default: 0, null: false, comment: "0: pending, 1: approved, 2: rejected"
      t.text :message, comment: "リクエストメッセージ"
      t.text :rejection_reason, comment: "却下理由"
      t.datetime :approved_at, comment: "承認日時"
      t.uuid :user_id, null: false, comment: "リクエスト送信者"
      t.uuid :company_id, null: false
      t.uuid :store_id, comment: "対象店舗（店舗管理者リクエストの場合）"
      t.uuid :approved_by_id, comment: "承認者のUser ID"
      t.timestamps
    end
    add_index :admin_requests, :user_id
    add_index :admin_requests, :company_id
    add_index :admin_requests, :store_id
    add_index :admin_requests, :approved_by_id
    add_index :admin_requests, [ :user_id, :status ]
    add_index :admin_requests, [ :company_id, :status ]
    add_foreign_key :admin_requests, :users, on_delete: :cascade
    add_foreign_key :admin_requests, :companies, on_delete: :cascade
    add_foreign_key :admin_requests, :stores
    add_foreign_key :admin_requests, :users, column: :approved_by_id, on_delete: :nullify

    # Active Storage Blobs テーブル
    create_table :active_storage_blobs, id: :uuid do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
    end
    add_index :active_storage_blobs, :key, unique: true

    # Active Storage Attachments テーブル
    create_table :active_storage_attachments, id: :uuid do |t|
      t.string :name, null: false
      t.string :record_type, null: false
      t.uuid :record_id, null: false
      t.uuid :blob_id, null: false
      t.uuid :company_id
      t.uuid :store_id
      t.datetime :created_at, null: false
    end
    add_index :active_storage_attachments, :blob_id
    add_index :active_storage_attachments, :company_id
    add_index :active_storage_attachments, :store_id
    add_index :active_storage_attachments, [ :record_type, :record_id, :name, :blob_id ], unique: true, name: 'index_active_storage_attachments_uniqueness'
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    add_foreign_key :active_storage_attachments, :companies
    add_foreign_key :active_storage_attachments, :stores

    # Active Storage Variant Records テーブル
    create_table :active_storage_variant_records, id: :uuid do |t|
      t.uuid :blob_id, null: false
      t.string :variation_digest, null: false
    end
    add_index :active_storage_variant_records, [ :blob_id, :variation_digest ], unique: true, name: 'index_active_storage_variant_records_uniqueness'
    add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id

    # Versions テーブル（PaperTrail）
    create_table :versions, id: :uuid do |t|
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.text :object
      t.uuid :company_id
      t.uuid :store_id
      t.datetime :created_at
    end
    add_index :versions, [ :item_type, :item_id ]
    add_index :versions, :company_id
    add_index :versions, :store_id
    add_foreign_key :versions, :companies
    add_foreign_key :versions, :stores
  end
end
