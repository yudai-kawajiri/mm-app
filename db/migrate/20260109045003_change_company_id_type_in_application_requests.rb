class ChangeCompanyIdTypeInApplicationRequests < ActiveRecord::Migration[8.1]
  def up
    # 既存のデータを削除（型変換できないため）
    execute "DELETE FROM application_requests"
    
    # company_id カラムを削除
    remove_column :application_requests, :company_id
    
    # uuid 型で company_id カラムを再作成
    add_column :application_requests, :company_id, :uuid
  end

  def down
    remove_column :application_requests, :company_id
    add_column :application_requests, :company_id, :integer
  end
end
