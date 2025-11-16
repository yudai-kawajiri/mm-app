# frozen_string_literal: true

# PlansController
#
# 製造計画（Plan）のCRUD操作を管理
#
# 機能:
#   - 計画の一覧表示（検索・カテゴリフィルタ・ページネーション・ソート機能）
#   - 計画の作成・編集・削除
#   - 計画のコピー・印刷機能
class Resources::PlansController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_id, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:name) },
    status: -> { order(:status, :name) },
    category: -> { joins(:category).order('categories.name', :name) }
  )

  # リソース検索（show, edit, update, destroy, copy, print）
  find_resource :plan, only: [:show, :edit, :update, :destroy, :copy, :print]

  # 計画一覧
  #
  # @return [void]
  def index
    sorted_index(
      Resources::Plan,
      default: 'name',
      scope: :all,
      includes: [:category]
    )
    @plan_categories = current_user.categories.for_plans.ordered
  end

  # 新規計画作成フォーム
  #
  # @return [void]
  def new
    @plan = current_user.plans.build
    @plan_categories = current_user.categories.for_plans.ordered
    @product_categories = current_user.categories.for_products.ordered
  end

  # 計画を作成
  #
  # @return [void]
  def create
    @plan = current_user.plans.build(plan_params)

    # エラー時のrender用に変数を事前設定
    @plan_categories = current_user.categories.for_plans.ordered
    @product_categories = current_user.categories.for_products.ordered

    respond_to_save(@plan, success_path: @plan)
  end

  # 計画詳細
  #
  # @return [void]
  def show
    @plan_products = @plan.plan_products.includes(:product)
    @product_categories = current_user.categories.for_products.ordered
  end

  # 計画編集フォーム
  #
  # @return [void]
  def edit
    @plan_categories = current_user.categories.for_plans.ordered
    @product_categories = current_user.categories.for_products.ordered
  end

  # 計画を更新
  #
  # @return [void]
  def update
    @plan.assign_attributes(plan_params)

    # エラー時のrender用に変数を事前設定
    @plan_categories = current_user.categories.for_plans.ordered
    @product_categories = current_user.categories.for_products.ordered

    respond_to_save(@plan, success_path: @plan)
  end

  # 計画を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@plan, success_path: resources_plans_url)
  end

  # 計画をコピー
  #
  # @return [void]
  def copy
    copied = @plan.create_copy(user: current_user)
    redirect_to resources_plans_path, notice: t('flash_messages.copy.success',
                                                resource: @plan.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Plan copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_plans_path, alert: t('flash_messages.copy.failure',
                                                resource: @plan.class.model_name.human)
  end

  # 印刷画面を表示
  #
  # @return [void]
  def print
    # 計画に関連する情報を取得
    plan_schedule = @plan.plan_schedules.order(scheduled_date: :desc).first
    @scheduled_date = plan_schedule&.scheduled_date

    # 月間予算から情報を取得
    if @scheduled_date
      monthly_budget = Management::MonthlyBudget
                        .where(user_id: current_user.id)
                        .where('budget_month = ?', @scheduled_date.beginning_of_month)
                        .first
      @budget = monthly_budget&.target_amount || 0
    else
      @budget = 0
    end

    # 製品一覧を製品マスタの display_order 順に取得
    @plan_products_for_print = @plan.plan_products
                                    .includes(product: [:category, { image_attachment: :blob }])
                                    .joins(:product)
                                    .order('products.display_order ASC, products.id ASC')
                                    .map do |pp|
      {
        product: pp.product,
        production_count: pp.production_count,
        price: pp.product.price,
        subtotal: pp.production_count * pp.product.price
      }
    end

    # 商品合計金額を計算（これを計画高として表示）
    @planned_revenue = @plan_products_for_print.sum { |item| item[:subtotal] }
    @total_product_cost = @planned_revenue

    # 達成率の計算
    @achievement_rate = if @budget > 0
                          ((@planned_revenue.to_f / @budget) * 100).round(1)
                        else
                          0
                        end

    # 原材料サマリーを取得（display_order 順）
    @materials_summary = @plan.calculate_materials_summary
                              .sort_by do |material_data|
                                material = Resources::Material.find(material_data[:material_id])
                                [material.display_order || 999999, material.id]
                              end

    # 印刷レイアウトを使用
    render layout: 'print'
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def plan_params
    params.require(:resources_plan).permit(
      :name,
      :category_id,
      :status,
      :note,
      plan_products_attributes: [
        :id,
        :product_id,
        :production_count,
        :display_order,
        :_destroy
      ]
    )
  end
end
