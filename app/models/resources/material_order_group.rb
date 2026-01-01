# frozen_string_literal: true

# 材料発注グループモデル - 発注時にまとめて扱う材料のグループを管理
class Resources::MaterialOrderGroup < ApplicationRecord
  belongs_to :company

  has_paper_trail

  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  has_many :materials, class_name: "Resources::Material", foreign_key: :order_group_id, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :store_id }
  validates :reading, presence: true, uniqueness: { scope: :store_id }

  scope :ordered, -> { order(:name) }

  scope :for_index, -> { order(created_at: :desc) }

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category, :store_id ],
    uniqueness_check_attributes: [ :name ]
  )
end
