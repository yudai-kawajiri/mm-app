class AddTenantAndStoreToActiveStorageAttachments < ActiveRecord::Migration[8.1]
  def change
    add_reference :active_storage_attachments, :tenant, null: false, foreign_key: true
    add_reference :active_storage_attachments, :store, null: true, foreign_key: true
  end
end
