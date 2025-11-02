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
    base_name = original_plan.name
    copy_count = Plan.where("name LIKE ?", "#{base_name}%").count

    new_plan = original_plan.dup
    new_plan.name = "#{base_name} (コピー#{copy_count})"
    new_plan.status = :draft
    new_plan.user_id = current_user.id

    ActiveRecord::Base.transaction do
      new_plan.save!

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

  def print
    @plan_products = @plan.plan_products
                          .includes(product: [:category, :product_materials, { product_materials: [:material, :unit] }])
                          .order(:id)

    @scheduled_date = @plan.plan_schedules.order(:scheduled_date).first&.scheduled_date
    @budget = @plan.plan_schedules.sum(:planned_revenue) || 0
    @total_cost = @plan_products.sum { |pp| pp.product.price * pp.production_count }
    @achievement_rate = @budget > 0 ? (@total_cost.to_f / @budget * 100).round(1) : 0
    @materials_summary = @plan.aggregated_material_requirements

    Rails.logger.info "========== Print Debug =========="
    Rails.logger.info "Plan ID: #{@plan.id}"
    Rails.logger.info "Plan Products Count: #{@plan_products.count}"
    Rails.logger.info "Materials Summary Count: #{@materials_summary.count}"
  end

  # 単一日付印刷
  def print_by_date
    @date = params[:date].to_date
    @plans = Plan.joins(:plan_schedules)
                 .where(user_id: current_user.id)
                 .where(plan_schedules: { scheduled_date: @date })
                 .includes(plan_products: { product: { product_materials: [:material, :unit] } })
                 .distinct

    @materials_summary = aggregate_materials_for_plans(@plans)
    @budget = PlanSchedule.where(plan: @plans, scheduled_date: @date).sum(:planned_revenue) || 0
    @total_cost = calculate_total_cost(@plans)
    @achievement_rate = @budget > 0 ? (@total_cost.to_f / @budget * 100).round(1) : 0
  end

  # 複数日付印刷
  def print_by_dates
    @dates = params[:dates].map(&:to_date).sort
    @start_date = @dates.first
    @end_date = @dates.last

    @plans = Plan.joins(:plan_schedules)
                 .where(user_id: current_user.id)
                 .where(plan_schedules: { scheduled_date: @dates })
                 .includes(plan_products: { product: { product_materials: [:material, :unit] } })
                 .distinct

    @plans_by_date = @plans.group_by do |plan|
      plan.plan_schedules.where(scheduled_date: @dates).first&.scheduled_date
    end

    @materials_summary = aggregate_materials_for_plans(@plans)
    @budget = PlanSchedule.where(plan: @plans, scheduled_date: @dates).sum(:planned_revenue) || 0
    @total_cost = calculate_total_cost(@plans)
    @achievement_rate = @budget > 0 ? (@total_cost.to_f / @budget * 100).round(1) : 0
  end

  private

  # 複数計画の原材料を集計
  def aggregate_materials_for_plans(plans)
    material_totals = Hash.new { |h, k| h[k] = { quantity: 0, name: nil, unit: nil, category: nil } }

    plans.each do |plan|
      plan.plan_products.each do |plan_product|
        product = plan_product.product
        production_count = plan_product.production_count

        product.product_materials.each do |pm|
          material = pm.material
          required_quantity = pm.quantity * production_count

          material_totals[material.id][:quantity] += required_quantity
          material_totals[material.id][:name] ||= material.name
          material_totals[material.id][:unit] ||= pm.unit&.name
          material_totals[material.id][:category] ||= material.category&.name
          material_totals[material.id][:display_order] ||= material.display_order || 999999
        end
      end
    end

    material_totals.map do |material_id, data|
      {
        material_id: material_id,
        material_name: data[:name],
        category: data[:category],
        total_quantity: data[:quantity],
        unit: data[:unit],
        display_order: data[:display_order]
      }
    end.sort_by { |m| [m[:display_order], m[:material_name]] }
  end

  # 計画高を計算
  def calculate_total_cost(plans)
    plans.sum do |plan|
      plan.plan_products.sum { |pp| pp.product.price * pp.production_count }
    end
  end

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

  def status_param
    params.permit(:status)[:status]
  end

  def load_plan_products
    @plan_products = @plan.plan_products.includes(:product)
  end
end