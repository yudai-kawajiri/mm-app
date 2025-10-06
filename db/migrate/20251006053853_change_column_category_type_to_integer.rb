class ChangeColumnCategoryTypeToInteger < ActiveRecord::Migration[8.0]
  def update
    # 既存のnilデータをデフォルト値に更新
    Category.where(category_type: nil).update_all(category_type: 'material')

    # string型からinteger型に変更
    # enumの値に基づいて変換
    Category.find_each do |category|
      case category.category_type
      when 'material'
        category.update_column(:category_type, 0)
      when 'product'
        category.update_column(:category_type, 1)
      when 'plan'
        category.update_column(:category_type, 2)
      else
        category.update_column(:category_type, 0)
      end
    end

    # カラムの型をintegerに変更
    change_column :categories, :category_type, :integer, null: false, default: 0
    end

    def down
    # ロールバック用
    change_column :categories, :category_type, :string, null: false
    end
  end
