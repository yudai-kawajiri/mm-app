class AddTenantToPlanProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :plan_products, :tenant, null: false, foreign_key: true
  end
end
