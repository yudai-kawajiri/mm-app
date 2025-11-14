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
      includes: [:category, :plan_products]
    )
    @plan_categories = current_user.categories.for_plans
  end

  # 新規計画作成フォーム
  #
  # @return [void]
  def new
    @plan = current_user.plans.build
    @plan_categories = current_user.categories.for_plans        # ← 追加
    @product_categories = current_user.categories.for_products
  end

  # 計画を作成
  #
  # @return [void]
  def create
    @plan = current_user.plans.build(plan_params)
    respond_to_save(@plan, success_path: @plan)
  end

  # 計画詳細
  #
  # @return [void]
  def show
    @plan_products = @plan.plan_products.includes(:product)
    @product_categories = current_user.categories.for_products
  end

  # 計画編集フォーム
  #
  # @return [void]
  def edit
    @plan_categories = current_user.categories.for_plans        # ← 追加
    @product_categories = current_user.categories.for_products
  end

  # 計画を更新
  #
  # @return [void]
  def update
    @plan.assign_attributes(plan_params)
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
    new_plan = @plan.deep_copy

    if new_plan.save
      redirect_to edit_resources_plan_path(new_plan),
                  notice: t('plans.copy.success')
    else
      redirect_to resources_plans_path,
                  alert: t('plans.copy.failure')
    end
  end

  # 計画を印刷
  #
  # @return [void]
  def print
    # 印刷処理の実装
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
        :quantity,
        :display_order,
        :_destroy
      ]
    )
  end
end
