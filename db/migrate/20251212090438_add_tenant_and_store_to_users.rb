class AddTenantAndStoreToUsers < ActiveRecord::Migration[8.1]
  def change
    # 1. まず null: true でカラム追加
    add_reference :users, :tenant, null: true, foreign_key: true
    add_reference :users, :store, null: true, foreign_key: true

    # 2. デフォルト会社 & 店舗を作成
    reversible do |dir|
      dir.up do
        # デフォルト会社作成
        default_tenant = Tenant.create!(
          name: "デフォルト会社",
          subdomain: "default",
          active: true
        )

        # デフォルト店舗作成
        default_store = Store.create!(
          tenant: default_tenant,
          name: "本社",
          code: "HQ",
          active: true
        )

        # 既存ユーザーに付与
        User.update_all(tenant_id: default_tenant.id, store_id: default_store.id)
      end
    end

    # 3. tenant_id を NOT NULL に変更
    change_column_null :users, :tenant_id, false
  end
end
