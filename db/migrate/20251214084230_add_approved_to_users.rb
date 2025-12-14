class AddApprovedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :approved, :boolean, default: false, null: false
    add_index :users, :approved

    # 既存ユーザーはすべて承認済みにする
    reversible do |dir|
      dir.up do
        User.update_all(approved: true)
      end
    end
  end
end
