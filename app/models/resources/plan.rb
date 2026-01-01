# frozen_string_literal: true

# 計画モデル - 製品の組み合わせと販売計画を管理
class Resources::Plan < ApplicationRecord
  # 定数：ロジックで使用するマジックナンバーを管理
  WEEKDAY_RANGE = (1..5).freeze # 月曜〜金曜
  DEFAULT_DISPLAY_ORDER = 999_999

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include NestedAttributeTranslatable
  include Copyable
  include HasReading
  include StatusChangeable

  # 関連付けられた商品モデルの翻訳設定
  nested_attribute_translation :plan_products, "Planning::PlanProduct"

  # スケジュールに使用されている場合はステータス変更を制限
  restrict_status_change_if_used_in :plan_schedules,
                                    foreign_key: :plan_id,
                                    class_name: "Planning::PlanSchedule"

  # 関連付け
  belongs_to :company
  belongs_to :store, optional: true
  belongs_to :category, class_name: "Resources::Category"

  has_many :plan_products, class_name: "Planning::PlanProduct", inverse_of: :plan, dependent: :destroy
  accepts_nested_attributes_for :plan_products,
                                allow_destroy: true,
                                reject_if: :reject_plan_products

  has_many :plan_schedules, class_name: "Planning::PlanSchedule", dependent: :nullify

  # 保存前コールバック
  before_save :reject_duplicate_plan_products

  # ステータス定義
  enum :status, {
    draft: 0,      # 下書き
    active: 1,     # 実施中
    completed: 2   # 完了
  }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :reading, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :category_id, presence: true
  validates :status, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # スコープ
  scope :for_index, -> { includes(:category).order(created_at: :desc) }
  scope :ordered, -> { order(:name) }
  scope :active_plans, -> { where(status: :active) }
  scope :available_for_schedule, -> { where(status: [ :draft, :active ]) }

  # カテゴリーによる絞り込み
  scope :filter_by_category_id, lambda { |category_id|
    where(category_id: category_id) if category_id.present?
  }

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category_id, :store_id ],
    uniqueness_check_attributes: [ :name, :reading ],
    associations_to_copy: [ :plan_products ],
    status_on_copy: :draft
  )

  # --- 計算・集計メソッド ---

  # 予定売上の合計を算出
  def expected_revenue
    plan_products.includes(:product).sum do |pp|
      (pp.product&.price.to_i) * (pp.production_count.to_i)
    end
  end

  # 表示用名称（名前 + 合計金額）
  def name_with_total
    formatted_total = ActionController::Base.helpers.number_with_delimiter(expected_revenue)
    "#{name}（¥#{formatted_total}）"
  end

  # --- スケジュール管理 ---

  def add_schedule(date, description: nil)
    plan_schedules.create(scheduled_date: date, description: description)
  end

  def add_schedules(dates, description: nil)
    dates.map do |date|
      plan_schedules.find_or_create_by(scheduled_date: date) do |schedule|
        schedule.description = description
      end
    end
  end

  # 指定期間の平日のみをスケジュール登録
  def add_weekday_schedules(start_date, end_date, description: nil)
    dates = (start_date..end_date).select { |d| WEEKDAY_RANGE.cover?(d.wday) }
    add_schedules(dates, description: description)
  end

  def scheduled_days_count
    plan_schedules.count
  end

  def total_actual_revenue
    plan_schedules.sum(:actual_revenue)
  end

  # --- 原材料集計ロジック ---

  # 計画全体で必要な原材料をグループ化して集計
  def aggregated_material_requirements
    materials_hash = {}

    plan_products.includes(product: { product_materials: [ :material, :unit ] }).each do |plan_product|
      plan_product.material_requirements.each do |material_data|
        m_id = material_data[:material_id]
        # material オブジェクトを一度取得し、以降は再利用する
        material = Resources::Material.find(m_id)
        m_name = material_data[:material_name]

        if materials_hash[m_name]
          materials_hash[m_name][:total_quantity] += material_data[:total_quantity]
          materials_hash[m_name][:total_weight] += material_data[:total_weight]
        else
          materials_hash[m_name] = material_data.merge(
            material: material,
            order_group_name: material.order_group_name
          )
        end
      end
    end

    calculate_order_group_requirements(materials_hash)
  end

  # 原材料ごとの使用量サマリーを算出
  def calculate_materials_summary
    material_totals = Hash.new { |h, k| h[k] = { total_quantity: 0, products: [] } }

    plan_products.includes(product: { product_materials: { material: [ :order_group, :unit_for_order ] } }).each do |pp|
      pp.product.product_materials.each do |pm|
        material = pm.material
        quantity = pm.quantity * pp.production_count

        summary = material_totals[material.id]
        summary[:material_id] = material.id
        summary[:material_name] = material.name
        summary[:total_quantity] += quantity
        summary[:order_group_name] = material.order_group&.name
        summary[:order_unit_name] = material.unit_for_order&.name
        summary[:display_order] = material.display_order || DEFAULT_DISPLAY_ORDER
        summary[:products] << { product_name: pp.product.name, quantity: quantity }

        if material.weight_based?
          calculate_weight_based_summary(summary, material, quantity)
        elsif material.count_based?
          calculate_count_based_summary(summary, material, quantity)
        end
      end
    end

    material_totals.values.sort_by { |m| [ m[:display_order], m[:material_id] ] }
  end

  private

  # 重量ベースの発注計算
  def calculate_weight_based_summary(summary, material, quantity)
    weight = quantity * (material.default_unit_weight || 0)
    summary[:total_weight] = weight
    summary[:weight_per_product] = material.default_unit_weight

    if material.unit_weight_for_order&.positive?
      summary[:required_order_quantity] = (weight.to_f / material.unit_weight_for_order).ceil
    else
      summary[:required_order_quantity] = 0
    end
  end

  # 個数ベースの発注計算
  def calculate_count_based_summary(summary, material, quantity)
    summary[:total_weight] = 0
    if material.pieces_per_order_unit&.positive?
      summary[:required_order_quantity] = (quantity.to_f / material.pieces_per_order_unit).ceil
    else
      summary[:required_order_quantity] = 0
    end
  end

  # 発注グループに基づいた最終集計処理（★N+1問題を最適化済み）
  def calculate_order_group_requirements(materials_hash)
    groups_hash = {}

    # ステップ1: グループごとの合計値を算出
    materials_hash.each do |_name, data|
      m = data[:material]
      group_key = m.order_group_name.presence || m.name

      groups_hash[group_key] ||= {
        weight: 0, qty: 0, type: m.measurement_type,
        unit_weight: m.unit_weight_for_order, pieces: m.pieces_per_order_unit,
        unit_name: m.unit_for_order&.name
      }
      groups_hash[group_key][:weight] += data[:total_weight]
      groups_hash[group_key][:qty] += data[:total_quantity]
    end

    # ステップ2: 各材料データを発注グループ単位でマージし、ソート順を付与
    materials_hash.map do |name, data|
      m = data[:material] # includes/メモリ内のオブジェクトを再利用
      group = groups_hash[m.order_group_name.presence || name]

      order_qty = case group[:type]
      when "count" then (group[:qty].to_f / group[:pieces]).round(2)
      when "weight" then (group[:weight].to_f / group[:unit_weight]).round(2)
      else 0
      end

      data.merge(
        required_order_quantity: order_qty,
        order_unit_name: group[:unit_name],
        is_grouped: m.order_group_name.present?,
        # DBへの再問い合わせを防ぐため、オブジェクトから直接取得
        display_order: m.display_order || DEFAULT_DISPLAY_ORDER
      ).except(:material)
    end.sort_by { |m| [ m[:display_order], m[:material_name] ] }
  end

  # 重複した商品を自動的に除外（データ整合性維持）
  def reject_duplicate_plan_products
    grouped = plan_products.reject(&:marked_for_destruction?).group_by(&:product_id)

    grouped.each do |_product_id, items|
      next if items.size <= 1
      # 2件目以降を削除対象としてマーク
      items[1..].each(&:mark_for_destruction)
    end
  end

  def reject_plan_products(attributes)
    attributes["product_id"].blank? && attributes["production_count"].blank?
  end
end
