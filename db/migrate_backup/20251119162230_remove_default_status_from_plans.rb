class RemoveDefaultStatusFromPlans < ActiveRecord::Migration[8.1]
  def change
    change_column_default :plans, :status, from: 0, to: nil
    change_column_null :plans, :status, true
  end
end
