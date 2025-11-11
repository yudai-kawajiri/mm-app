class AddPlanProductsSnapshotToPlanSchedules < ActiveRecord::Migration[7.2]
  def change
    # 日別の商品構成スナップショットを保存するカラムを追加
    add_column :plan_schedules, :plan_products_snapshot, :jsonb, default: {}, null: false, comment: '計画商品のスナップショット（日別調整用）'

    # JSONB カラムにインデックスを追加（検索高速化）
    add_index :plan_schedules, :plan_products_snapshot, using: :gin
  end
end
