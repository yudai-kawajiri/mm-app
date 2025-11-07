class Plan < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 名前検索スコープを組み込み
  include NameSearchable
  include UserAssociatable
  # 関連付け
  belongs_to :category
  has_many :plan_products, inverse_of: :plan, dependent: :destroy
  accepts_nested_attributes_for :plan_products,
    { allow_destroy: true,
    reject_if: :reject_plan_products }
  has_many :plan_schedules, dependent: :destroy

  # status カラムに enum を定義
  enum :status, {
  draft: 0,      # 下書き
  active: 1,     # 実施中
  completed: 2  # 完了
}

  # ステータス関連のスコープ
  scope :active_plans, -> { where(status: :active) }
  scope :available_for_schedule, -> { where(status: [ :draft, :active ]) }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :category_id, presence: true
  validates :status, presence: true


  # インデックス表示用のスコープ (N+1問題対策と並び替え)
  scope :for_index, -> { includes(:category).order(created_at: :desc) }

  # カテゴリIDでの絞り込み
  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  def expected_revenue
  plan_products.includes(:product).sum do |pp|
    # productがnilでも安全に0を返す
    price = pp.product&.price.to_i
    # production_countがnilの場合は0として扱う
    count = pp.production_count.to_i
    price * count
  end
end

  # ドロップダウン用の表示名（計画名と合計金額）
  def name_with_total
    total = expected_revenue
    formatted_total = ActionController::Base.helpers.number_with_delimiter(total)
    "#{name}（¥#{formatted_total}）"
  end

  # 指定日にスケジュールを追加
  def add_schedule(date, note: nil)
    plan_schedules.create(scheduled_date: date, note: note)
  end

  # 複数日にスケジュールを一括追加
  def add_schedules(dates, note: nil)
    dates.map do |date|
      plan_schedules.find_or_create_by(scheduled_date: date) do |schedule|
        schedule.note = note
      end
    end
  end

  # 平日のみスケジュール追加
  def add_weekday_schedules(start_date, end_date, note: nil)
    dates = (start_date..end_date).select { |d| d.wday.between?(1, 5) }
    add_schedules(dates, note: note)
  end

  # スケジュールされている日数
  def scheduled_days_count
    plan_schedules.count
  end

  # 合計実績売上
  def total_actual_revenue
    plan_schedules.sum(:actual_revenue)
  end

  # この計画全体で使う原材料を集計（新しい構造に対応）
  def aggregated_material_requirements
    materials_hash = {}

    plan_products.includes(product: { product_materials: [:material, :unit] }).each do |plan_product|
      plan_product.material_requirements.each do |material_data|
        material_id = material_data[:material_id]
        material = Material.find(material_id)
        material_name = material_data[:material_name]

        # キーは material_name（同じ名前なら合算）
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
        # 既存グループに重量・個数を加算（発注量計算用）
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

      # グループ全体の発注量を計算（切り上げなし、小数点表示）
      required_order_quantity = case group_data[:measurement_type]
      when 'count'
        # 個数ベース: 合計個数 ÷ 1発注単位あたりの個数
        (group_data[:group_total_quantity].to_f / group_data[:pieces_per_order_unit]).round(2)
      when 'weight'
        # 重量ベース: 合計重量 ÷ 1発注単位あたりの重量
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
      material = Material.find(m[:material_id])
      [material.display_order || 999999, m[:material_name]]
    end
  end

  private

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_plan_products(attributes)
    attributes["product_id"].blank? && attributes["production_count"].blank?
  end
end
