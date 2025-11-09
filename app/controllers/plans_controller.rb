# frozen_string_literal: true

# PlansController
#
# 計画のCRUD操作を管理
#
# 機能:
#   - 計画の一覧表示（検索・カテゴリフィルタ・ページネーション）
#   - 計画の作成・編集・削除
#   - ステータス管理（draft, active, completed）
#   - 計画コピー機能（商品構成も複製）
#   - 印刷機能（材料集計表示）
#   - 重複エラーハンドリング
class PlansController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q, :category_id

  # リソース検索
  find_resource :plan, only: [:show, :edit, :update, :destroy, :update_status, :copy, :print]

  # カテゴリロード
  before_action -> { load_categories_for("plan", as: :plan) }, only: [:index, :new, :edit, :create, :update]
  before_action -> { load_categories_for("product", as: :product) }, only: [:new, :edit, :create, :update, :show]
  before_action :load_plan_products, only: [:show]

  # 計画一覧
  #
  # @return [void]
  def index
    @plans = apply_pagination(
      Plan.for_index.search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  # 新規計画作成フォーム
  #
  # @return [void]
  def new
    @plan = current_user.plans.build
    @plan.status = nil
  end

  # 計画を作成
  #
  # @return [void]
  def create
    @plan = current_user.plans.build(plan_params)
    respond_to_save(@plan, success_path: @plan)
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicate_error(e)
  end

  # 計画詳細
  #
  # @return [void]
  def show; end

  # 計画編集フォーム
  #
  # @return [void]
  def edit
    @plan.plan_products.build unless @plan.plan_products.any?
  end

  # 計画を更新
  #
  # @return [void]
  def update
    @plan.assign_attributes(plan_params)
    respond_to_save(@plan, success_path: @plan)
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicate_error(e)
  end

  # 計画を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@plan, success_path: plans_url)
  end

  # ステータス更新アクション
  #
  # @return [void]
  def update_status
    new_status = status_param

    if Plan.statuses.keys.include?(new_status)
      @plan.update(status: new_status)
      status_text = t("activerecord.enums.plan.status.#{new_status}")
      redirect_to plans_path, notice: t('plans.messages.status_updated',
                                        name: @plan.name,
                                        status: status_text)
    else
      redirect_to plans_path, alert: t('api.errors.invalid_status')
    end
  end

  # 計画をコピー
  #
  # 計画名のユニーク制約を考慮して名前を生成
  # 商品構成も複製
  #
  # @return [void]
  def copy
    original_plan = @plan
    base_name = original_plan.name
    copy_count = 1
    new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"

    # ユニーク制約を考慮して名前を生成
    while Plan.exists?(name: new_name, category_id: original_plan.category_id, user_id: current_user.id)
      copy_count += 1
      new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"
    end

    new_plan = original_plan.dup
    new_plan.name = new_name
    new_plan.status = :draft
    new_plan.user_id = current_user.id

    ActiveRecord::Base.transaction do
      new_plan.save!

      # 商品構成も複製
      original_plan.plan_products.each do |plan_product|
        new_plan.plan_products.create!(
          product_id: plan_product.product_id,
          production_count: plan_product.production_count
        )
      end
    end

    redirect_to plans_path, notice: t('plans.messages.copy_success',
                                      original_name: original_plan.name,
                                      new_name: new_plan.name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Plan copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to plans_path, alert: t('plans.messages.copy_failed',
                                    error: e.record.errors.full_messages.join(', '))
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "Plan copy failed (duplicate): #{e.message}"
    redirect_to plans_path, alert: t('plans.messages.copy_failed_duplicate')
  end

  # 印刷用ページ
  #
  # 材料集計、予算、達成率を表示
  #
  # @return [void]
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
    @achievement_rate = @budget.positive? ? (@total_cost.to_f / @budget * 100).round(1) : 0
    @materials_summary = @plan.aggregated_material_requirements

    Rails.logger.info "========== Print Debug =========="
    Rails.logger.info "Plan ID: #{@plan.id}"
    Rails.logger.info "Scheduled Date: #{@scheduled_date}"
    Rails.logger.info "Plan Products Count: #{@plan_products.count}"
    Rails.logger.info "Materials Summary Count: #{@materials_summary.count}"
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
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

  # ステータスパラメータ
  #
  # @return [String]
  def status_param
    params.permit(:status)[:status]
  end

  # 計画商品をロード
  #
  # @return [void]
  def load_plan_products
    @plan_products = @plan.plan_products.includes(:product)
  end

  # 重複エラーのハンドリング
  #
  # @param exception [ActiveRecord::RecordNotUnique] 重複エラー
  # @return [void]
  def handle_duplicate_error(exception)
    Rails.logger.error "Duplicate key error: #{exception.message}"

    if exception.message.include?('index_plans_on_name_and_category_id')
      # 計画名の重複
      @plan.errors.add(:name, t('plans.errors.duplicate_name'))
    elsif exception.message.include?('index_plan_products_on_plan_id_and_product_id')
      # 同じ商品の重複
      @plan.errors.add(:base, t('plans.errors.duplicate_product'))
    else
      # その他の重複エラー
      @plan.errors.add(:base, t('api.errors.invalid_parameters'))
    end

    # フォームを再表示
    load_categories_for("plan", as: :plan)
    load_categories_for("product", as: :product)
    render(@plan.new_record? ? :new : :edit, status: :unprocessable_entity)
  end
end
