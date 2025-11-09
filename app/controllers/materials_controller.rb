# frozen_string_literal: true

# MaterialsController
#
# 材料のCRUD操作を管理
#
# 機能:
#   - 材料の一覧表示（検索・カテゴリフィルタ・ページネーション）
#   - 材料の作成・編集・削除
#   - 表示順の並び替え（drag & drop）
#   - 計測方法の管理（重量ベース・個数ベース）
class MaterialsController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q, :category_id

  # カテゴリロード
  before_action -> { load_categories_for("material", as: :material) }, only: [:index, :new, :edit, :create, :update]

  # リソース検索
  find_resource :material, only: [:show, :edit, :update, :destroy]

  # 材料一覧
  #
  # @return [void]
  def index
    @materials = apply_pagination(
      Material.includes(:category, :unit_for_product, :unit_for_order, :production_unit, :order_group)
              .search_and_filter(search_params)
              .ordered
    )
    @search_categories = @material_categories
    set_search_term_for_view
  end

  # 材料詳細
  #
  # @return [void]
  def show; end

  # 新規材料作成フォーム
  #
  # @return [void]
  def new
    @material = current_user.materials.build
  end

  # 材料を作成
  #
  # @return [void]
  def create
    @material = current_user.materials.build(material_params)
    respond_to_save(@material, success_path: @material)
  end

  # 材料編集フォーム
  #
  # @return [void]
  def edit; end

  # 材料を更新
  #
  # @return [void]
  def update
    @material.assign_attributes(material_params)
    respond_to_save(@material, success_path: @material)
  end

  # 材料を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@material, success_path: materials_url)
  end

  # 材料の表示順を並び替え
  #
  # ドラッグ&ドロップで並び替えたIDの順序を受け取る
  #
  # @return [void]
  def reorder
    material_ids = reorder_params[:material_ids]

    Rails.logger.debug "=== Received material_ids: #{material_ids.inspect}"

    Material.update_display_orders(material_ids)
    head :ok
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def material_params
    params.require(:material).permit(
      :name,
      :category_id,
      :default_unit_weight,
      :unit_for_product_id,
      :unit_weight_for_order,
      :unit_for_order_id,
      :pieces_per_order_unit,
      :minimum_order_quantity,
      :measurement_type,
      :order_group_id,
      :order_group_method,
      :new_order_group_name,
      :description,
      :production_unit_id
    )
  end

  # 並び替え用パラメータ
  #
  # @return [ActionController::Parameters]
  def reorder_params
    params.permit(material_ids: [])
  end
end
