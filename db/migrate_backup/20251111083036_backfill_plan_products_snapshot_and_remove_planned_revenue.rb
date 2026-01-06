class BackfillPlanProductsSnapshotAndRemovePlannedRevenue < ActiveRecord::Migration[8.1]
  def up
    # 古いレコードにスナップショット生成
    Planning::PlanSchedule.where("plan_products_snapshot = '{}'::jsonb").find_each do |schedule|
      next unless schedule.plan.present?

      products_data = schedule.plan.plan_products.map do |pp|
        {
          product_id: pp.product_id,
          production_count: pp.production_count,
          price: pp.product.price,
          subtotal: pp.production_count * pp.product.price
        }
      end

      snapshot = {
        products: products_data,
        total_cost: products_data.sum { |p| p[:subtotal] },
        created_at: Time.current.iso8601
      }

      schedule.update_column(:plan_products_snapshot, snapshot)
    end

    # planned_revenue カラムを削除
    remove_column :plan_schedules, :planned_revenue
  end

  def down
    # planned_revenue カラムを復元
    add_column :plan_schedules, :planned_revenue, :integer

    # スナップショットから planned_revenue を復元
    Planning::PlanSchedule.find_each do |schedule|
      if schedule.plan_products_snapshot.present? && schedule.plan_products_snapshot['total_cost'].present?
        schedule.update_column(:planned_revenue, schedule.plan_products_snapshot['total_cost'])
      end
    end
  end
end
