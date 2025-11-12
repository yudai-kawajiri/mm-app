# frozen_string_literal: true

# PlansController
#
# 計画のCRUD操作を管理
#
# 機能:
#   - 計画の一覧表示（検索・カテゴリフィルタ・ページネーション・ソート機能）
#   - 計画の作成・編集・削除
#   - ステータス管理（draft, active, completed）
#   - 計画コピー機能（商品構成も複製）
#   - 印刷機能（材料集計表示）
#   - 重複エラーハンドリング
#   - 数値入力のサニタイズ処理（NumericSanitizer）
class Resources::PlansController < AuthenticatedController
  include NumericSanitizer
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_id, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:name) },
    status: -> { order(:status, :name) },
    category: -> { joins(:category).order('categories.name', :name) },
    updated_at: -> { order(updated_at: :desc) }
  )

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
    sorted_index(Resources::Plan, default: 'name')
    @search_categories = @plan_categories
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
    @plan = current_user.plans.build(sanitized_plan_params)
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
    @plan.assign_attributes(sanitized_plan_params)
    respond_to_save(@plan, success_path: @plan)
  rescue ActiveRecord::RecordNotUnique => e
    handle_duplicate_error(e)
  end

  # 計画を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@plan, success_path: resources_plans_url)
  end

  # ステータス更新アクション
  #
  # @return [void]
  def update_status
    new_status = status_param

    if Resources::Plan.statuses.keys.include?(new_status)
      @plan.update(status: new_status)
      status_text = t("activerecord.enums.plan.status.#{new_status}")
      redirect_to resources_plans_path, notice: t('plans.messages.status_updated',
                                        name: @plan.name,
                                        status: status_text)
    else
      redirect_to resources_plans_path, alert: t('api.errors.invalid_status')
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

    while Resources::Plan.exists?(name: new_name, category_id: original_plan.category_id, user_id: current_user.id)
      copy_count += 1
      new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"
    end

    new_plan = original_plan.dup
    new_plan.name = new_name
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

    redirect_to resources_plans_path, notice: t('plans.messages.copy_success',
                                      original_name: original_plan.name,
                                      new_name: new_plan.name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Plan copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_plans_path, alert: t('plans.messages.copy_failed',
                                    error: e.record.errors.full_messages.join(', '))
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "Plan copy failed (duplicate): #{e.message}"
    redirect_to resources_plans_path, alert: t('plans.messages.copy_failed_duplicate')
  end

  # 印刷用ページ
  #
  # 材料集計、予算、達成率を表示
  #
  # @return [void]
  def print
    @scheduled_date = params[:date]&.to_date || @plan.plan_schedules.order(:scheduled_date).first&.scheduled_date

    # その日の plan_schedule を取得
    @plan_schedule = @plan.plan_schedules.find_by(scheduled_date: @scheduled_date)

    # 商品データの取得: スナップショットがあればそれを使用、なければ計画の最新値
    if @plan_schedule&.has_snapshot?
      # スナップショットから取得（過去のデータが保持される）
      @plan_products_for_print = @plan_schedule.snapshot_products
      @total_product_cost = @plan_schedule.plan_products_snapshot['total_cost']
    else
      # 計画の最新値を使用
      @plan_products = @plan.plan_products
                            .includes(product: [:category, :product_materials, { product_materials: [:material, :unit] }])
                            .order(:id)
      @plan_products_for_print = @plan_products.map do |pp|
        {
          product: pp.product,
          production_count: pp.production_count,
          price: pp.product.price,
          subtotal: pp.product.price * pp.production_count
        }
      end
      @total_product_cost = @plan_products.sum { |pp| pp.product.price * pp.production_count }
    end

    # 予算: daily_targets から取得（整数化）
    if @scheduled_date.present?
      daily_target = current_user.daily_targets.find_by(target_date: @scheduled_date)
      @budget = (daily_target&.target_amount || 0).to_i
    else
      @budget = 0
    end

    # 計画高: plan_schedule から取得
    @planned_revenue = @plan_schedule&.current_planned_revenue || 0

    # 達成率: 計画高 ÷ 予算 × 100
    @achievement_rate = @budget.positive? ? (@planned_revenue.to_f / @budget * 100).round(1) : 0

    # 材料集計
    @materials_summary = @plan.aggregated_material_requirements

    Rails.logger.info "========== Print Debug =========="
    Rails.logger.info "Plan ID: #{@plan.id}"
    Rails.logger.info "Scheduled Date: #{@scheduled_date}"
    Rails.logger.info "Has Snapshot: #{@plan_schedule&.has_snapshot? || false}"
    Rails.logger.info "Budget (from daily_targets): #{@budget}"
    Rails.logger.info "Planned Revenue: #{@planned_revenue}"
    Rails.logger.info "Total Product Cost: #{@total_product_cost}"
    Rails.logger.info "Achievement Rate: #{@achievement_rate}%"
    Rails.logger.info "Products Count: #{@plan_products_for_print.count}"
    Rails.logger.info "Materials Summary Count: #{@materials_summary.count}"
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def plan_params
    permitted = params.require(:resources_plan).permit(
      :category_id,
      :user_id,
      :name,
      :description,
      :status
    )

    # plan_products_attributes を手動で処理
    if params[:resources_plan][:plan_products_attributes].present?
      products_attrs = {}
      params[:resources_plan][:plan_products_attributes].each do |key, attrs|
        products_attrs[key] = attrs.permit(
          :id,
          :_destroy,
          :product_id,
          :production_count
        )
      end
      permitted[:plan_products_attributes] = products_attrs
    end

    permitted
  end

  # 数値パラメータのサニタイズ処理
  #
  # 対象フィールド:
  #   - plan_products[].production_count: 製造数（整数のみ）
  #
  # @return [Hash]
  def sanitized_plan_params
    # 完全にハッシュに変換
    params_hash = plan_params.to_h.deep_symbolize_keys

    if params_hash[:plan_products_attributes].present?
      params_hash[:plan_products_attributes] = params_hash[:plan_products_attributes].transform_values do |product_attrs|
        next product_attrs if product_attrs[:_destroy] == '1'

        sanitize_numeric_params(
          product_attrs,
          without_comma: [:production_count]
        )
      end
    end

    params_hash
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
      @plan.errors.add(:name, t('plans.errors.duplicate_name'))
    elsif exception.message.include?('index_plan_products_on_plan_id_and_product_id')
      @plan.errors.add(:base, t('plans.errors.duplicate_product'))
    else
      @plan.errors.add(:base, t('api.errors.invalid_parameters'))
    end

    load_categories_for("plan", as: :plan)
    load_categories_for("product", as: :product)
    render(@plan.new_record? ? :new : :edit, status: :unprocessable_entity)
  end
end
