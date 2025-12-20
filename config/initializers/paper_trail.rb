# frozen_string_literal: true

# PaperTrail の設定
PaperTrail.config.enabled = true

# カスタム Version モデル
class PaperTrail::Version < ActiveRecord::Base
  before_create :set_store_and_company_id

  private

  def set_store_and_company_id
    return unless item

    # store_id を設定
    self.store_id = item.store_id if item.respond_to?(:store_id)

    # company_id を設定
    if item.respond_to?(:company_id)
      self.company_id = item.company_id
    elsif item.respond_to?(:company)
      self.company_id = item.company&.id
    end
  end
end
