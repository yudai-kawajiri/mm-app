# frozen_string_literal: true

# UnitsController
#
# 単位（Unit）のCRUD操作を管理
#
# 機能:
#   - 単位の一覧表示（検索・カテゴリフィルタ・ページネーション・ソート機能）
#   - 単位の作成・編集・削除
#   - 単位のコピー
class Resources::UnitsController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:reading) },
    category: -> { order(:category, :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :unit, only: [:show, :edit, :update, :destroy, :copy]

  # 単位一覧
  #
  # @return [void]
  def index
    # 基本クエリ
    @units = Resources::Unit.all

    # ソート適用
    @units = apply_sort(@units, default: 'name')

    # カテゴリーフィルタリング
    if params[:category].present?
      @units = @units.filter_by_category(params[:category])
    end

    # 名前検索（直接実装）
    if params[:q].present?
      @units = @units.search_by_name(params[:q])
    end

    # ページネーション
    @units = @units.page(params[:page])
  end

  # 新規単位作成フォーム
  #
  # @return [void]
  def new
    @unit = current_user.units.build
  end

  # 単位を作成
  #
  # @return [void]
  def create
    @unit = current_user.units.build(unit_params)
    respond_to_save(@unit)
  end

  # 単位詳細
  #
  # @return [void]
  def show; end

  # 単位編集フォーム
  #
  # @return [void]
  def edit; end

  # 単位を更新
  #
  # @return [void]
  def update
    @unit.assign_attributes(unit_params)
    respond_to_save(@unit)
  end

  # 単位を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@unit, success_path: resources_units_url)
  end

  # 単位をコピー
  #
  # @return [void]
  def copy
    copied = @unit.create_copy(user: current_user)
    redirect_to resources_units_path, notice: t('flash_messages.copy.success',
                                                  resource: @unit.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Unit copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_units_path, alert: t('flash_messages.copy.failure',
                                                resource: @unit.class.model_name.human)
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def unit_params
    params.require(:resources_unit).permit(:name, :reading, :category, :description)
  end
end
