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

    # カレンダーから渡された日付を使用（なければ最初のスケジュール）
    @scheduled_date = params[:date]&.to_date || @plan.plan_schedules.order(:scheduled_date).first&.scheduled_date

    # 該当日付の予算を取得
    if params[:date].present?
      @budget = @plan.plan_schedules.where(scheduled_date: @scheduled_date).sum(:planned_revenue) || 0
    else
      @budget = @plan.plan_schedules.sum(:planned_revenue) || 0
    end

    @total_cost = @plan_products.sum { |pp| pp.product.price * pp.production_count }
    @achievement_rate = @budget > 0 ? (@total_cost.to_f / @budget * 100).round(1) : 0
    @materials_summary = @plan.aggregated_material_requirements

    Rails.logger.info "========== Print Debug =========="
    Rails.logger.info "Plan ID: #{@plan.id}"
    Rails.logger.info "Scheduled Date: #{@scheduled_date}"
    Rails.logger.info "Plan Products Count: #{@plan_products.count}"
    Rails.logger.info "Materials Summary Count: #{@materials_summary.count}"
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

  def status_param
    params.permit(:status)[:status]
  end

  def load_plan_products
    @plan_products = @plan.plan_products.includes(:product)
  end
end