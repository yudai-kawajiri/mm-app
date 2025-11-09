# frozen_string_literal: true

# UnitsController
#
# 単位（Unit）のCRUD操作を管理
#
# 機能:
#   - 単位の一覧表示（検索・カテゴリフィルタ・ページネーション）
#   - 単位の作成・編集・削除
#   - カテゴリ別フィルタリング（production, ordering, manufacturing）
class Resources::UnitsController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q, :category

  # リソース検索（show, edit, update, destroy）
  find_resource :unit, only: [:show, :edit, :update, :destroy]

  # 単位一覧
  #
  # @return [void]
  def index
    @units = apply_pagination(
      Resources::Unit.for_index
          .search_and_filter(search_params)
          .filter_by_category(search_params[:category])
    )
    set_search_term_for_view
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
    respond_to_save(@unit, success_path: @unit)
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
    respond_to_save(@unit, success_path: @unit)
  end

  # 単位を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@unit, success_path: units_url)
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def unit_params
    params.require(:unit).permit(:name, :category, :description)
  end
end
