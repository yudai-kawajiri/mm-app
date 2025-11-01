# app/controllers/plans_controller.rb
class PlansController < AuthenticatedController
  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id

  find_resource :plan, only: [ :show, :edit, :update, :destroy, :update_status, :copy, :print ]


  before_action -> { load_categories_for("plan", as: :plan) }, only: [ :index, :new, :edit, :create, :update ]
  before_action -> { load_categories_for("product", as: :product) }, only: [ :new, :edit, :create, :update ]
  before_action :load_plan_products, only: [ :show ]

  def index
    @plans = apply_pagination(
      Plan.for_index.search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  def new
    @plan = current_user.plans.build
    @plan.status = nil
  end

  def create
    @plan = current_user.plans.build(plan_params)
    respond_to_save(@plan, success_path: @plan)
  end

  def show; end

  def edit
    @plan.plan_products.build unless @plan.plan_products.any?
  end

  def update
    @plan.assign_attributes(plan_params)
    respond_to_save(@plan, success_path: @plan)
  end

  def destroy
    respond_to_destroy(@plan, success_path: plans_url)
  end

  # ステータス更新アクション
  def update_status
    # @planは既にfind_resourceで設定済み
    new_status = status_param

    if Plan.statuses.keys.include?(new_status)
      @plan.update(status: new_status)
      status_text = t("activerecord.enums.plan.status.#{new_status}")
      redirect_to plans_path, notice: "計画「#{@plan.name}」のステータスを「#{status_text}」に変更しました。"
    else
      redirect_to plans_path, alert: "無効なステータスです。"
    end
  end

  def copy
    original_plan = @plan

    # 同じベース名の計画数をカウント
    base_name = original_plan.name
    copy_count = Plan.where("name LIKE ?", "#{base_name}%").count

    # 計画本体をコピー
    new_plan = original_plan.dup
    new_plan.name = "#{base_name} (コピー#{copy_count})"
    new_plan.status = :draft
    new_plan.user_id = current_user.id

    ActiveRecord::Base.transaction do
      new_plan.save!

      # 商品構成もコピー
      original_plan.plan_products.each do |plan_product|
        new_plan.plan_products.create!(
          product_id: plan_product.product_id,
          production_count: plan_product.production_count
        )
      end
    end

    redirect_to plans_path, notice: "計画「#{original_plan.name}」をコピーしました（新規計画名: #{new_plan.name}）"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to plans_path, alert: "計画のコピーに失敗しました: #{e.message}"
  end


  private

  def plan_params
    params.require(:plan).permit(
      :category_id,
      :user_id,
      :name,
      :description,
      :status,
      plan_products_attributes: [
        :id,
        :_destroy,
        :product_id,
        :production_count
      ]
    )
  end

  # ステータス更新用のパラメータ
  def status_param
    params.permit(:status)[:status]
  end

  # N+1対策: plan_productsを事前ロード
  def load_plan_products
    @plan_products = @plan.plan_products.includes(:product)
  end

  def print
  # @plan は find_resource で自動設定される

  # 商品情報を取得
  @plan_products = @plan.plan_products
                        .includes(product: [:category, :product_materials, { product_materials: [:material, :unit] }])
                        .order(:id)

  # 実施日（最初のスケジュール）
  @scheduled_date = @plan.plan_schedules.order(:scheduled_date).first&.scheduled_date

  # 予算（計画売上の合計）
  @budget = @plan.plan_schedules.sum(:planned_revenue) || 0

  # 計画高（商品合計金額）
  @total_cost = @plan_products.sum { |pp| pp.product.price * pp.production_count }

  # 達成率
  @achievement_rate = @budget > 0 ? (@total_cost.to_f / @budget * 100).round(1) : 0

  # 原材料を集計
  materials_hash = {}

  @plan_products.each do |plan_product|
    product = plan_product.product
    production_count = plan_product.production_count

    product.product_materials.each do |pm|
      material = pm.material
      key = material.id

      # この計画での使用数量 = 商品1個あたりの使用量 × 製造数
      usage_quantity = pm.quantity * production_count

      if materials_hash[key]
        # 既存の原材料に数量を加算
        materials_hash[key][:usage_quantity] += usage_quantity
      else
        # 新規原材料を追加
        materials_hash[key] = {
          material: material,
          unit: pm.unit,
          usage_quantity: usage_quantity
        }
      end
    end
  end

  # 原材料をソート（名前順）
  @materials_summary = materials_hash.values.sort_by { |m| m[:material].name }

  render layout: 'print'
end


end
