# frozen_string_literal: true

# PaperTrail の設定
PaperTrail.config.enabled = true

# カスタム Version モデル
class PaperTrail::Version < ActiveRecord::Base
  before_create :set_store_and_tenant_id

  private

  def set_store_and_tenant_id
    return unless item

    # store_id を設定
    self.store_id = item.store_id if item.respond_to?(:store_id)

    # tenant_id を設定
    if item.respond_to?(:tenant_id)
      self.tenant_id = item.tenant_id
    elsif item.respond_to?(:tenant)
      self.tenant_id = item.tenant&.id
    end
  end
end
