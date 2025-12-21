# Plan
#
# 計画モデル - 製品の組み合わせと販売計画を管理
#
# 使用例:
#   Plan.create(name: "ランチセット", category_id: 1, status: :active)
#   Plan.active_plans
#   plan.expected_revenue
class Resources::Plan < ApplicationRecord
  # 定数
  WEEKDAY_RANGE = (1..5).freeze
  DEFAULT_DISPLAY_ORDER = 999_999

  # フォーム定数
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

  nested_attribute_translation :plan_products, "Planning::PlanProduct"

  # ステータス変更制限を追加
  restrict_status_change_if_used_in :plan_schedules,
                                    foreign_key: :plan_id,
                                    class_name: "Planning::PlanSchedule"

  # 関連付け
  # マルチテナント対応
  belongs_to :company
  belongs_to :store, optional: true

  belongs_to :category, class_name: "Resources::Category"
  has_many :plan_products, class_name: "Planning::PlanProduct", inverse_of: :plan, dependent: :destroy
  accepts_nested_attributes_for :plan_products,
                                allow_destroy: true,
                                reject_if: :reject_plan_products

  # 保存前コールバック（重複商品を除外）
  before_save :reject_duplicate_plan_products

  has_many :plan_schedules, class_name: "Planning::PlanSchedule", dependent: :nullify

  # 計画のステータス定義
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

  # 一覧画面用：登録順（新しい順）
  scope :for_index, -> { includes(:category).order(created_at: :desc) }

  # セレクトボックス用：名前順
  scope :ordered, -> { order(:name) }

  # 実施中の計画を取得
  scope :active_plans, -> { where(status: :active) }

  # スケジュール可能な計画を取得（下書きまたは実施中）
  scope :available_for_schedule, -> { where(status: [ :draft, :active ]) }

  # ―
  #
  # @param category_id [Integer, nil] カテゴリーID
  # @return [ActiveRecord::Relation] 絞り込み結果
  scope :filter_by_category_id, lambda { |category_id|
    where(category_id: category_id) if category_id.present?
  }

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category_id, :store_id ],
    uniqueness_check_attributes: [ :name, :reading ],
    associations_to_copy: [ :plan_products ],
    additional_attributes: {
      status: :draft
    }
  )

  # 予定売上を計算
  #
  # @return [Integer] 予定売上
  def expected_revenue
    plan_products.includes(:product).sum do |pp|
      price = pp.product&.price.to_i
      count = pp.production_count.to_i
      price * count
    end
  end

  # ドロップダウン用の表示名（計画名と合計金額）
  #
  # @return [String] 表示名
  def name_with_total
    total = expected_revenue
    formatted_total = ActionController::Base.helpers.number_with_delimiter(total)
    "#{name}（¥#{formatted_total}）"
  end

  # 指定日にスケジュールを追加
  #
  # @param date [Date] 対象日
  # @param description [String, nil] メモ
  # @return [PlanSchedule] 作成されたスケジュール
  def add_schedule(date, description: nil)
    plan_schedules.create(scheduled_date: date, description: description)
  end

  # 複数日にスケジュールを一括追加
  #
  # @param dates [Array<Date>] 対象日の配列
  # @param description [String, nil] メモ
  # @return [Array<PlanSchedule>] 作成されたスケジュールの配列
  def add_schedules(dates, description: nil)
    dates.map do |date|
      plan_schedules.find_or_create_by(scheduled_date: date) do |schedule|
        schedule.description = description
      end
    end
  end

  # 平日のみスケジュール追加
  #
  # @param start_date [Date] 開始日
  # @param end_date [Date] 終了日
  # @param description [String, nil] メモ
  # @return [Array<PlanSchedule>] 作成されたスケジュールの配列
  def add_weekday_schedules(start_date, end_date, description: nil)
    dates = (start_date..end_date).select { |d| WEEKDAY_RANGE.cover?(d.wday) }
    add_schedules(dates, description: description)
  end

  # スケジュールされている日数
  #
  # @return [Integer] 日数
  def scheduled_days_count
    plan_schedules.count
  end

  # 合計実績売上
  #
  # @return [Integer] 合計実績売上
  def total_actual_revenue
    plan_schedules.sum(:actual_revenue)
  end

  # この計画全体で使う原材料を集計
  #
  # @return [Array<Hash>] 原材料必要量の配列
  def aggregated_material_requirements
    materials_hash = {}

    plan_products.includes(product: { product_materials: [ :material, :unit ] }).each do |plan_product|
      plan_product.material_requirements.each do |material_data|
        material_id = material_data[:material_id]
        material = Resources::Material.find(material_id)
        material_name = material_data[:material_name]

        if materials_hash[material_name]
          # 既存の原材料に加算
          materials_hash[material_name][:total_quantity] += material_data[:total_quantity]
          materials_hash[material_name][:total_weight] += material_data[:total_weight]
        else
          # 新規原材料を追加
          materials_hash[material_name] = {
            material_id: material_id,
            material_name: material_name,
            quantity: material_data[:quantity],
            unit_weight: material_data[:unit_weight],
            weight_per_product: material_data[:weight_per_product],
            total_quantity: material_data[:total_quantity],
            total_weight: material_data[:total_weight],
            material: material,
            order_group_name: material.order_group_name
          }
        end
      end
    end

    # 発注グループごとに発注量を計算
    groups_hash = {}

    materials_hash.each do |material_name, data|
      material = data[:material]
      group_key = material.order_group_name.present? ? material.order_group_name : material_name

      if groups_hash[group_key]
        # 既存グループに重量・個数を加算
        groups_hash[group_key][:group_total_weight] += data[:total_weight]
        groups_hash[group_key][:group_total_quantity] += data[:total_quantity]
      else
        # 新規グループ
        groups_hash[group_key] = {
          group_total_weight: data[:total_weight],
          group_total_quantity: data[:total_quantity],
          measurement_type: material.measurement_type,
          unit_weight_for_order: material.unit_weight_for_order,
          pieces_per_order_unit: material.pieces_per_order_unit,
          unit_for_order_name: material.unit_for_order&.name
        }
      end
    end

    # 各原材料に発注量を追加
    materials_hash.map do |material_name, data|
      material = data[:material]
      group_key = material.order_group_name.present? ? material.order_group_name : material_name
      group_data = groups_hash[group_key]

      # グループ全体の発注量を計算（小数点表示）
      required_order_quantity = case group_data[:measurement_type]
      when "count"
                                  # 個数ベース: 合計個数 ÷ 1発注単位当の個数
                                  (group_data[:group_total_quantity].to_f / group_data[:pieces_per_order_unit]).round(2)
      when "weight"
                                  # 重量ベース: 合計重量 ÷ 1発注単位当の重量
                                  (group_data[:group_total_weight].to_f / group_data[:unit_weight_for_order]).round(2)
      else
                                  0
      end

      {
        material_id: data[:material_id],
        material_name: material_name,
        quantity: data[:quantity],
        unit_weight: data[:unit_weight],
        weight_per_product: data[:weight_per_product],
        total_quantity: data[:total_quantity],
        total_weight: data[:total_weight],
        required_order_quantity: required_order_quantity,
        order_unit_name: group_data[:unit_for_order_name],
        order_group_name: material.order_group_name,
        is_grouped: material.order_group_name.present?
      }
    end.sort_by do |m|
      material = Resources::Material.find(m[:material_id])
      [ material.display_order || DEFAULT_DISPLAY_ORDER, m[:material_name] ]
    end
  end

  # 原材料サマリーを計算
  #
  # @return [Array<Hash>] 原材料ごとの使用量サマリー
  def calculate_materials_summary
    # 計画に含まれる全製品の原材料を集計
    material_totals = Hash.new { |h, k| h[k] = { total_quantity: 0, products: [] } }

    plan_products.includes(product: { product_materials: { material: [ :order_group, :unit_for_order ] } }).each do |pp|
      pp.product.product_materials.each do |pm|
        material = pm.material
        quantity = pm.quantity * pp.production_count

        material_totals[material.id][:material_id] = material.id
        material_totals[material.id][:material_name] = material.name
        material_totals[material.id][:total_quantity] += quantity
        material_totals[material.id][:order_group_name] = material.order_group&.name
        material_totals[material.id][:order_unit_name] = material.unit_for_order&.name
        # ★追加: display_orderを含める
        material_totals[material.id][:display_order] = material.display_order || Resources::Plan::DEFAULT_DISPLAY_ORDER
        material_totals[material.id][:products] << {
          product_name: pp.product.name,
          quantity: quantity
        }

        # 重量ベースの場合の計算
        if material.weight_based?
          weight = quantity * (material.default_unit_weight || 0)
          material_totals[material.id][:total_weight] = weight
          material_totals[material.id][:weight_per_product] = material.default_unit_weight

          # 発注数量の計算
          if material.unit_weight_for_order && material.unit_weight_for_order > 0
            required_units = (weight.to_f / material.unit_weight_for_order).ceil
            material_totals[material.id][:required_order_quantity] = required_units
          else
            material_totals[material.id][:required_order_quantity] = 0
          end
        # 個数ベースの場合の計算
        elsif material.count_based?
          material_totals[material.id][:total_weight] = 0

          # 発注数量の計算
          if material.pieces_per_order_unit && material.pieces_per_order_unit > 0
            required_units = (quantity.to_f / material.pieces_per_order_unit).ceil
            material_totals[material.id][:required_order_quantity] = required_units
          else
            material_totals[material.id][:required_order_quantity] = 0
          end
        end
      end
    end

    # ★追加: ここでソートして返す
    material_totals.values.sort_by { |m| [ m[:display_order], m[:material_id] ] }
  end

  private

  # 重複した商品を削除（カテゴリタブとALLタブで同じ商品が追加された場合）
  def reject_duplicate_plan_products
    grouped = plan_products.reject(&:marked_for_destruction?).group_by(&:product_id)

    grouped.each do |product_id, items|
      next if items.size <= 1

      Rails.logger.warn " Duplicate plan_product detected: product_id=#{product_id}, count=#{items.size}"

      items[1..].each do |duplicate|
        Rails.logger.warn "  → Removing duplicate: id=#{duplicate.id || 'new'}"
        duplicate.mark_for_destruction
      end
    end
  end

  # product_id と production_count の両方が空の場合にレコードを無視
  def reject_plan_products(attributes)
    attributes["product_id"].blank? && attributes["production_count"].blank?
  end
end
