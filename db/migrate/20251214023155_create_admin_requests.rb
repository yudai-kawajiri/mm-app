class CreateAdminRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_requests do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, comment: 'リクエスト送信者'
      t.references :store, foreign_key: true, comment: '対象店舗（店舗管理者リクエストの場合）'
      
      t.integer :request_type, null: false, default: 0, comment: '0: store_admin_request'
      t.integer :status, null: false, default: 0, comment: '0: pending, 1: approved, 2: rejected'
      
      t.text :message, comment: 'リクエストメッセージ'
      t.text :rejection_reason, comment: '却下理由'
      
      t.bigint :approved_by_id, comment: '承認者のUser ID'
      t.datetime :approved_at, comment: '承認日時'

      t.timestamps
    end
    
    add_foreign_key :admin_requests, :users, column: :approved_by_id
    add_index :admin_requests, :approved_by_id
    add_index :admin_requests, [:tenant_id, :status]
    add_index :admin_requests, [:user_id, :status]
  end
end
