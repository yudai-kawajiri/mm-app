# frozen_string_literal: true

# MaterialOrderGroupsController
#
# 材料発注グループのCRUD操作を管理
#
# 機能:
#   - 発注グループの一覧表示（全ユーザー共有）
#   - 発注グループの作成・編集・削除
#   - グループ削除時の材料への影響（dependent: :nullify）
class MaterialOrderGroupsController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q

  # リソース検索
  find_resource :material_order_group, only: [:show, :edit, :update, :destroy]

  # 発注グループ一覧
  #
  # 全ユーザーのグループを表示（ログインユーザーなら誰でも閲覧可能）
  #
  # @return [void]
  def index
    @material_order_groups = apply_pagination(
      MaterialOrderGroup.includes(:materials)
                        .ordered_by_name
                        .search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  # 新規発注グループ作成フォーム
  #
  # @return [void]
  def new
    @material_order_group = MaterialOrderGroup.new
  end

  # 発注グループを作成
  #
  # @return [void]
  def create
    @material_order_group = MaterialOrderGroup.new(material_order_group_params)
    @material_order_group.user = current_user
    respond_to_save(@material_order_group, success_path: material_order_groups_path)
  end

  # 発注グループ詳細
  #
  # @return [void]
  def show; end

  # 発注グループ編集フォーム
  #
  # @return [void]
  def edit; end

  # 発注グループを更新
  #
  # @return [void]
  def update
    @material_order_group.assign_attributes(material_order_group_params)
    respond_to_save(@material_order_group, success_path: material_order_groups_path)
  end

  # 発注グループを削除
  #
  # dependent: :nullify により、紐付いている原材料のorder_group_idがnullになる
  #
  # @return [void]
  def destroy
    respond_to_destroy(@material_order_group, success_path: material_order_groups_path)
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def material_order_group_params
    params.require(:material_order_group).permit(:name)
  end
end
